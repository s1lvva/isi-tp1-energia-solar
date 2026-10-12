-- Esquema inicial do data mart (esqueleto — a completar na Fase 3)

CREATE SCHEMA IF NOT EXISTS staging;   -- dados lidos das fontes, já limpos
CREATE SCHEMA IF NOT EXISTS mart;      -- modelo final para análise e dashboard
CREATE SCHEMA IF NOT EXISTS etl;       -- registo das execuções

-- Registo de cada execução do ETL (alimentado pelo job orquestrador)
CREATE TABLE IF NOT EXISTS etl.execucao (
    id              SERIAL PRIMARY KEY,
    job             VARCHAR(100) NOT NULL,
    inicio          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    fim             TIMESTAMPTZ,
    estado          VARCHAR(20),          -- OK | ERRO
    linhas_lidas    INTEGER,
    linhas_escritas INTEGER,
    mensagem        TEXT
);

-- Dimensão tempo, ao quarto de hora (granularidade comum às fontes)
CREATE TABLE IF NOT EXISTS mart.dim_tempo (
    id_tempo        SERIAL PRIMARY KEY,
    instante_utc    TIMESTAMPTZ NOT NULL UNIQUE,
    data_local      DATE        NOT NULL,
    hora_local      SMALLINT    NOT NULL,
    quarto_hora     SMALLINT    NOT NULL,
    dia_semana      SMALLINT    NOT NULL,
    mes             SMALLINT    NOT NULL
);
