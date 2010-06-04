; Program to process r4rs.idx entries.

(define main 0)
(define aux 1)

(define (make-entry key font main/aux page)
  (list key font main/aux page))
(define (entry-key x) (car x))
(define (entry-font x) (cadr x))
(define (entry-main/aux x) (caddr x))
(define (entry-page x) (cadddr x))

(define *database* '())

(define (index-entry key font main/aux page)
  (set! *database*
        (cons (make-entry (string-downcase key)
                          font
                          main/aux
                          page)
              *database*))
  #t)

(define (create-index p)
  (define (loop)
    (if (null? *database*)
        'done
        (begin (process-key (collect-entries) p)
               (loop))))
  (set! *database*
        (sort *database*
              (lambda (x y)
                (string<? (entry-key x)
                          (entry-key y)))))
  (loop))

(define (collect-entries)
  (define (loop key entries)
    (cond ((null? *database*) entries)
          ((string=? key (entry-key (car *database*)))
           (let ((x (car *database*)))
             (set! *database* (cdr *database*))
             (loop key (cons x entries))))
          (else entries)))
  (loop (caar *database*) '()))

(define (process-key entries p)
  (let ((entries (sort entries entry<?)))
    (if (not (consistent? entries))
        (begin (display "Inconsistent entries:")
               (newline)
               (pretty-print entries)
               (newline)
               (newline)))
    (let ((key (entry-key (car entries)))
          (font (entry-font (car entries)))
          (main? (entry-main/aux (car entries)))
          (pages (remove-duplicates (map entry-page entries))))
      (if main?
          (write-entries key font (car pages) (cdr pages) p)
          (write-entries key font #f pages p)))))

(define (entry<? x y)
  (let ((x1 (entry-main/aux x))
        (y1 (entry-main/aux y)))
    (or (< x1 y1)
        (and (eq? x1 y1)
             (< (entry-page x) (entry-page y))))))

(define (consistent? entries)
  (let ((x (car entries)))
    (let ((key (entry-key x))
          (font (entry-font x)))
      (every? (lambda (x)
                (and (string=? key (entry-key x))
                     (string=? font (entry-font x))
                     ;(eq? aux (entry-main/aux x))
                     ))
              (cdr entries)))))

(define (remove-duplicates x)
  (define (loop x y)
    (cond ((null? x) (reverse y))
          ((memq (car x) y) (loop (cdr x) y))
          (else (loop (cdr x) (cons (car x) y)))))
  (loop (cdr x) (list (car x))))

(define *last-key* "%")
(define *s1* (string-append "\\item{" (list->string '(#\\))))
(define *s2* "{")
(define *s3* "}}{\\hskip .75em}")
(define *semi* "\; ")
(define *comma* ", ")

(define (write-entries key font main pages p)
  (if (and (char-alphabetic? (string-ref key 0))
           (not (char=? (string-ref *last-key* 0)
                        (string-ref key 0))))
      (begin (display "\\indexspace" p)
             (newline p)))
  (set! *last-key* key)
  (display (string-append *s1* font *s2* key *s3*) p)
  (if main
      (begin (write main p)
             (if (not (null? pages))
                 (display *semi* p))))
  (if (not (null? pages))
      (begin (write (car pages) p)
             (for-each (lambda (page)
                         (display *comma* p)
                         (write page p))
                       (cdr pages))))
  (newline p))
