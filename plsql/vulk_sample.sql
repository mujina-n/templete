set serveroutput on;
set echo on;
set timing on;
/*------------------------------------------------------------------------------
  �ꊇ�����ŃA�b�v�f�[�g����ꍇ�̃T���v���e���v���[�g
  �@�悭�����̎Ј��e�[�u���̃t���O���X�V������e�ňȉ����L��
--------------------------------------------------------------------------------*/
DECLARE

  -- Oracle�G���[
  sql_code NUMBER;
  sql_errm VARCHAR2(2048);
  sql_stmt VARCHAR2(2048);
  
  -- FETCH�֘A
  SIZE_FETCH CONSTANT NUMBER := 1000;
  bulkNotCompEx EXCEPTION;
  PRAGMA EXCEPTION_INIT(bulkNotCompEx, -24381);

  -- �T�u���W���[���߂�l
  STATUS_NORMAL CONSTANT NUMBER := 0;
  STATUS_ERROR CONSTANT NUMBER := 1;
  STATUS_FATAL CONSTANT NUMBER := -1;

  -- �Ɩ��p���O(Key�ɂȂ���̂�ێ�)
  dept_no DEPT.DEPT_NO%TYPE;
  
  -- �J�[�\���錾
  CURSOR cur_work IS
    SELECT
      dpt.*
    FROM
      DEPT dpt
    WHERE
      dpt.FLG = 1
    ;
  TYPE type_work IS TABLE OF cur_work%ROWTYPE INDEX BY BINARY_INTEGER;
  rec_work type_work;

  ----------------------------------------------------------------------------
  -- �T�u�֐�
  ----------------------------------------------------------------------------
  FUNCTION subMain(p_cnt out NUMBER, p_rec in type_work)
    RETURN NUMBER
  IS
  BEGIN
    
    sql_stmt := '
      UPDATE
        DEPT
      SET
        FLG = :1
      WHERE
        DEPT_NO = :2'
      ;
    FORALL i IN p_rec.First..p_rec.LAST SAVE EXCEPTIONS
      EXECUTE IMMEDIATE sql_stmt USING 0, p_rec(i).DEPT_NO;

    p_cnt := SQL%ROWCOUNT;
    RETURN STATUS_NORMAL;
  EXCEPTION
  WHEN bulkNotCompEx THEN
    FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
      dbms_output.put_line('[END_ERROR:subMain()' 
        || ',' || p_rec(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).DEPT_NO
        || ']'
        || SQLERRM(-1 * SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
    END LOOP;
    p_cnt := SQL%ROWCOUNT - SQL%BULK_EXCEPTIONS.COUNT;
    RETURN STATUS_ERROR;
  WHEN OTHERS THEN
    sql_errm := SQLERRM;
    dbms_output.put_line('[END_FATAL:subMain()]' || sql_errm);
    RETURN STATUS_FATAL;
  END;

  ----------------------------------------------------------------------------
  -- ���C���֐�
  ----------------------------------------------------------------------------
  PROCEDURE main
  IS
    -- ���ʊ֐��̃X�e�[�^�X
    status NUMBER DEFAULT STATUS_ERROR;
    -- ��������
    cnt_trun NUMBER DEFAULT 0;
    cnt_all NUMBER DEFAULT 0;
    cnt_normal NUMBER DEFAULT 0;
  BEGIN

    OPEN cur_work;
    LOOP
      FETCH cur_work BULK COLLECT INTO rec_work LIMIT SIZE_FETCH;
      EXIT WHEN cur_work%ROWCOUNT = 0;

      status := subUpd(cnt_trun, rec_work);
      IF status != STATUS_NORMAL THEN
        ROLLBACK;
        EXIT WHEN cur_work%NOTFOUND OR cur_work%NOTFOUND IS NULL;
        CONTINUE;
      END IF;
 
      --TODO COMMIT;
      ROLLBACK;
      cnt_normal := cnt_normal + cnt_trun;
      EXIT WHEN cur_work%NOTFOUND OR cur_work%NOTFOUND IS NULL;
    END LOOP;

    cnt_all := cur_work%ROWCOUNT;
    CLOSE cur_work;
    dbms_output.put_line('��������:' || cnt_normal || '/' || cnt_all);
  EXCEPTION
  WHEN OTHERS THEN
    sql_code := SQLCODE;
    sql_errm := SQLERRM;
    dbms_output.put_line('[END_FATAL:main():FETCH�J�[�\���G���[�A�Ď��s���Ă��������B]' || sql_errm);
    ROLLBACK;
  END;

---------
-- �J�n
---------
BEGIN

  main;
END;
