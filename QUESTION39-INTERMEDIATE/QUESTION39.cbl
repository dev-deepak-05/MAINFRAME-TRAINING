IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKTRAN.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      * TRANSACTION DETAILS
       01 WS-TRAN-ID       PIC X(10)
          VALUE 'TRX000001'.

       01 WS-FROM-ACCOUNT  PIC X(10)
          VALUE 'ACC0000001'.

       01 WS-TO-ACCOUNT    PIC X(10)
          VALUE 'ACC0000002'.

       01 WS-AMOUNT        PIC S9(9)V99 COMP-3
          VALUE 1000.00.

       01 WS-BALANCE       PIC S9(9)V99 COMP-3
          VALUE ZERO.

       01 WS-ROWS          PIC S9(9) COMP-5
          VALUE ZERO.

       01 WS-STATUS        PIC X(20)
          VALUE SPACES.

       01 WS-FAIL-STEP     PIC X(30)
          VALUE SPACES.

      * DB2 SQL COMMUNICATION AREA
       EXEC SQL INCLUDE SQLCA END-EXEC.

       PROCEDURE DIVISION.

       MAIN-PARA.

           DISPLAY '--------------------------------'
           DISPLAY ' BANK TRANSACTION PROCESSING'
           DISPLAY '--------------------------------'

           DISPLAY 'TRANSACTION ID: ' WS-TRAN-ID
           DISPLAY 'TRANSFER AMOUNT: ' WS-AMOUNT

           MOVE 'PROCESSING' TO WS-STATUS

      *================================================
      * OPERATION 1: READ AND VALIDATE SENDER ACCOUNT
      *================================================

           DISPLAY 'OPERATION 1: VALIDATING ACCOUNT'

           EXEC SQL
               SELECT BALANCE
                 INTO :WS-BALANCE
                 FROM ACCOUNT_MASTER
                WHERE ACCOUNT_ID = :WS-FROM-ACCOUNT
           END-EXEC

           IF SQLCODE NOT = 0
               MOVE 'VALIDATION' TO WS-FAIL-STEP
               PERFORM HANDLE-FAILURE
               GOBACK
           END-IF

           DISPLAY 'SENDER ACCOUNT FOUND'

           IF WS-BALANCE < WS-AMOUNT
               MOVE 'INSUFFICIENT FUNDS' TO WS-FAIL-STEP
               PERFORM HANDLE-FAILURE
               GOBACK
           END-IF

      *================================================
      * OPERATION 2: DEBIT SENDER ACCOUNT
      *================================================

           DISPLAY 'OPERATION 2: DEBITING ACCOUNT'

           EXEC SQL
               UPDATE ACCOUNT_MASTER
                  SET BALANCE = BALANCE - :WS-AMOUNT
                WHERE ACCOUNT_ID = :WS-FROM-ACCOUNT
                  AND BALANCE >= :WS-AMOUNT
           END-EXEC

           IF SQLCODE NOT = 0
               MOVE 'DEBIT' TO WS-FAIL-STEP
               PERFORM HANDLE-FAILURE
               GOBACK
           END-IF

           MOVE SQLERRD(3) TO WS-ROWS

           IF WS-ROWS NOT = 1
               MOVE 'DEBIT ROW FAILURE' TO WS-FAIL-STEP
               PERFORM HANDLE-FAILURE
               GOBACK
           END-IF

           DISPLAY 'DEBIT SUCCESSFUL'

      *================================================
      * OPERATION 3: CREDIT RECEIVER ACCOUNT
      *================================================

           DISPLAY 'OPERATION 3: CREDITING ACCOUNT'

           EXEC SQL
               UPDATE ACCOUNT_MASTER
                  SET BALANCE = BALANCE + :WS-AMOUNT
                WHERE ACCOUNT_ID = :WS-TO-ACCOUNT
           END-EXEC

           IF SQLCODE NOT = 0
               MOVE 'CREDIT' TO WS-FAIL-STEP
               PERFORM HANDLE-FAILURE
               GOBACK
           END-IF

           MOVE SQLERRD(3) TO WS-ROWS

           IF WS-ROWS NOT = 1
               MOVE 'CREDIT ROW FAILURE' TO WS-FAIL-STEP
               PERFORM HANDLE-FAILURE
               GOBACK
           END-IF

           DISPLAY 'CREDIT SUCCESSFUL'

      *================================================
      * OPERATION 4: INSERT TRANSFER HISTORY
      *================================================

           DISPLAY 'OPERATION 4: INSERTING HISTORY'

           EXEC SQL
               INSERT INTO TRANSFER_HISTORY
               (
                   TRANSACTION_ID,
                   FROM_ACCOUNT,
                   TO_ACCOUNT,
                   AMOUNT
               )
               VALUES
               (
                   :WS-TRAN-ID,
                   :WS-FROM-ACCOUNT,
                   :WS-TO-ACCOUNT,
                   :WS-AMOUNT
               )
           END-EXEC

           IF SQLCODE NOT = 0
               MOVE 'HISTORY INSERT' TO WS-FAIL-STEP
               PERFORM HANDLE-FAILURE
               GOBACK
           END-IF

           DISPLAY 'HISTORY INSERT SUCCESSFUL'

      *================================================
      * ALL OPERATIONS SUCCESSFUL: COMMIT
      *================================================

           DISPLAY 'ALL OPERATIONS SUCCESSFUL'

           EXEC SQL
               COMMIT
           END-EXEC

           IF SQLCODE = 0
               MOVE 'COMMITTED' TO WS-STATUS
               DISPLAY 'TRANSACTION COMMITTED'
           ELSE
               MOVE 'UNKNOWN' TO WS-STATUS
               DISPLAY 'COMMIT RESULT UNKNOWN'
               DISPLAY 'RECOVERY REQUIRED'
               DISPLAY 'SQLCODE: ' SQLCODE
           END-IF

           DISPLAY 'FINAL STATUS: ' WS-STATUS

           GOBACK.

      *================================================
      * FAILURE HANDLING: ROLLBACK
      *================================================

       HANDLE-FAILURE.

           DISPLAY 'TRANSACTION FAILURE'
           DISPLAY 'FAILED OPERATION: ' WS-FAIL-STEP
           DISPLAY 'SQL ERROR CODE: ' SQLCODE

           EXEC SQL
               ROLLBACK
           END-EXEC

           IF SQLCODE = 0
               MOVE 'ROLLED BACK' TO WS-STATUS
               DISPLAY 'ROLLBACK SUCCESSFUL'
               DISPLAY 'TRANSACTION ROLLED BACK'
           ELSE
               MOVE 'UNKNOWN' TO WS-STATUS
               DISPLAY 'ROLLBACK FAILED'
               DISPLAY 'MANUAL RECOVERY REQUIRED'
               DISPLAY 'ROLLBACK SQLCODE: ' SQLCODE
           END-IF

           DISPLAY 'FINAL STATUS: ' WS-STATUS.
