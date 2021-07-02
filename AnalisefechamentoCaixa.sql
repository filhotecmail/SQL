 /*{**************************************************************************
         PROGRAMA LEOPARD DATABSE FIREBIRD - VERSAO 2.5.XX
         ANALISTA: CARLOS A DIAS DA S.
         DATA.: 02/07/2021
         OBJETIVO: TRATA,FORTAMA E RECUPERA INFORMAÇÕES DO MOVIMENTO DE CAIXAS
         TRANSMITIDOS DOS TERMINAIS FRENTE PDV
         SOBRE.:
         A FUNÇÃO EXTRACT , EXTRAI HORAS MINUTOS OU SEGUNDOS DE UM TIPO TIME
         E DIA , MES E ANO DE UM TIPO DATE
         LPAD COMPLETA AS CASAS A DIREITA PARA O FORMATO  00/00/0000 OU 00:00:00
    
      *************************************************************************}*/
CREATE OR ALTER PROCEDURE GETFECHAMENTOPDVS (
    TIPOA INTEGER,
    PDATEINI DATE,
    PDATEFIM DATE)
RETURNS (
    "PDV Nroº" VARCHAR(4),
    "Nroº MOVIMENTO" VARCHAR(6),
    "Operador" VARCHAR(60),
    "Abertura" VARCHAR(39),
    "Fechamento" VARCHAR(40),
    "( + ) R$ T.Liquido" VARCHAR(24),
    "( = ) Vol de vendas" BIGINT,
    "( - ) R$ T.Estornado" VARCHAR(24),
    "( = ) R$ T.Cancelamentos" VARCHAR(24),
    "( + ) R$ T.Dinheiro" VARCHAR(24),
    "( + ) R$ T.C Debito" VARCHAR(24),
    "( + ) R$ T.C Credito" VARCHAR(24),
    "( + ) R$ T.C loja" VARCHAR(24),
    "( + ) R$ T.Cheque" VARCHAR(24),
    "( + ) R$ T.V Refeição" VARCHAR(24),
    "( + ) R$ T. V Alimentação" VARCHAR(24),
    "( + ) R$ T. Outros" VARCHAR(24),
    "( + ) R$ T. V Presente" VARCHAR(24),
    "( = ) R$ T. Dinheiro GV" VARCHAR(24),
    "( = ) R$ T. Fiscal" VARCHAR(24),
    "( = ) Volume fiscal" INTEGER)
AS
BEGIN
  FOR
    SELECT
           LPAD(F.CX51NUMPDV,4,0) AS "PDV Nroº",
           LPAD(F.CX01ABID,6,0) AS "Nroº MOVIMENTO",
           F.CX05ABNOMEOPERADOR AS "Operador",
           /*{FORMATA A DATA E HORA DE ABERTURTA DO CAIXA}*/
           'Aberto em '||LPAD(EXTRACT( DAY FROM F.CX02ABDATA ),2,0)||'/'
                       ||LPAD(EXTRACT( MONTH FROM F.CX02ABDATA ),2,0)||'/'
                       ||EXTRACT( YEAR FROM F.CX02ABDATA )
                       ||' as '
                       ||EXTRACT( HOUR FROM F.CX03ABHORA)||':'
                       ||EXTRACT( MINUTE FROM F.CX03ABHORA),
          /*{FORMATA A DATA E HORA DO FECHAMENTO DE CAIXA}*/
          'Fechado em '||LPAD(EXTRACT( DAY FROM F.CX42DATAFECH ),2,0)||'/'
                       ||LPAD(EXTRACT( MONTH FROM F.CX42DATAFECH ),2,0)||'/'
                       ||EXTRACT( YEAR FROM F.CX42DATAFECH )
                       ||' as '
                       ||EXTRACT( HOUR FROM F.CX43HORAFECH)||':'
                       ||EXTRACT( MINUTE FROM F.CX43HORAFECH),
    
           'R$ '||SUM(F.CX13VLTVENDASLIQ),
                  SUM(F.CX16QTDTVVALIDAS),
           'R$ '||SUM(F.CX10TOTALESTORNOS),
           'R$ '||SUM(IIF( C.VENDA_SITUACAO  = 'CANCELADA', C.VENDA_VLTOTAL,0.00)),
           'R$ '||SUM( F.CX17TOTALDINHEIRO ),
           'R$ '||SUM( F.CX18TOTALCDEBITO ),
           'R$ '||SUM( F.CX19TOTALCCREDITO ),
           'R$ '||SUM( F.CX20TOTALCRLOJA ),
           'R$ '||SUM( F.CX21TOTALCHEQUE ),
           'R$ '||SUM( F.CX22TOTALVREFEICAO ),
           'R$ '||SUM( F.CX23TOTALVALIMENT ),
           'R$ '||SUM( F.CX24TOTALMOVOUTROS ),
           'R$ '||SUM( F.CX24TOTALVLPRESENTE ),
           'R$ '||SUM( F.CX26DINHEIROGV ),
         /*{RECUPERA O VALOR FISCAL EMITIDO NO TERMINAL PDV NA DATA DO FECHAMENTO}*/
           'R$ '||COALESCE(( (SELECT SUM( VV.VENDA_VLTOTAL)
                       FROM MOVPDV_VENDAS VV
                       WHERE VV.SAT_SITUACAO = 'EMITIDO'
                       AND VV.PDV_NUMPDV = F.CX51NUMPDV
                       AND VV.PDV_IDCAIXA = F.CX01ABID )  ),0),
         /*{RECUPERA O VOLUME FISCAL EMITIDO NO TERMINAL PDV NA DATA DO FECHAMENTO}*/
           COALESCE(( (SELECT COUNT( VV.ID)
                       FROM MOVPDV_VENDAS VV
                       WHERE VV.SAT_SITUACAO = 'EMITIDO'
                       AND VV.PDV_NUMPDV = F.CX51NUMPDV
                       AND VV.PDV_IDCAIXA = F.CX01ABID )  ),0)
     FROM POOLS_CXFECHAMENTO F
          JOIN MOVPDV_VENDAS C ON ( C.PDV_NUMPDV = F.CX51NUMPDV
                               AND  C.PDV_IDCAIXA = F.CX01ABID  )
     WHERE (   CASE :TIPOA
               WHEN 0 THEN F.CX02ABDATA
               WHEN 1 THEN F.CX42DATAFECH
               WHEN 2 THEN F.CX42DATAFECH
               END ) BETWEEN IIF( :TIPOA = 2,CAST('01/01/1999' AS DATE),:PDATEINI )
                         AND IIF( :TIPOA = 2,CAST('01/01/2500' AS DATE),:PDATEFIM )
     GROUP BY
           F.CX51NUMPDV,
           F.CX05ABNOMEOPERADOR,
           F.CX03ABHORA,
           F.CX02ABDATA,
           F.CX43HORAFECH,
           F.CX42DATAFECH,
           F.CX01ABID
     ORDER BY
            F.CX51NUMPDV,
            F.CX02ABDATA,
            F.CX03ABHORA,
            F.CX42DATAFECH,
            F.CX43HORAFECH
    INTO :"PDV Nroº",
         :"Nroº MOVIMENTO",
         :"Operador",
         :"Abertura",
         :"Fechamento",
         :"( + ) R$ T.Liquido",
         :"(=)Vol de vendas",
         :"( - ) R$ T.Estornado",
         :"( = ) R$ T.Cancelamentos",
         :"( + ) R$ T.Dinheiro",
         :"( + ) R$ T.C Debito",
         :"( + ) R$ T.C Credito",
         :"( + ) R$ T.C loja",
         :"( + ) R$ T.Cheque",
         :"( + ) R$ T.V Refeição",
         :"( + ) R$ T. V Alimentação",
         :"( + ) R$ T. Outros",
         :"( + ) R$ T. V Presente",
         :"( = ) R$ T. Dinheiro GV",
         :"( = ) R$ T. Fiscal",
         :"( = ) Volume fiscal"
  DO
  BEGIN
    SUSPEND;
  END
END^