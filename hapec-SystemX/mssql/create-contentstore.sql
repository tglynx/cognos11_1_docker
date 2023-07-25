IF  NOT EXISTS (SELECT * FROM sys.databases WHERE name = N'dbHAPECContentstore')
  BEGIN
    CREATE DATABASE dbHAPECContentstore 
  END;
