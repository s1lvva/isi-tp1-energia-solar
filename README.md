# Vale a pena pôr painéis?
### ETL com dados abertos para avaliar o autoconsumo solar doméstico

| | |
|---|---|
| **Aluno** | André Silva — n.º 27965 |
| **Unidade Curricular** | Integração de Sistemas de Informação (ISI) |
| **Curso** | Licenciatura em Engenharia de Sistemas Informáticos — IPCA |
| **Ano letivo** | 2026/27 — Trabalho Prático I |
| **Docentes** | Luís Ferreira e Óscar Ribeiro |
| **Ferramenta** | Pentaho Data Integration (Kettle) 10.2 CE |

**🎬 Vídeo de demonstração:** _(colocar aqui o link)_

---

## 1. Objetivo

Uma família em Braga, com um consumo anual de 4000 kWh, pondera instalar painéis solares. O processo ETL cruza, hora a hora, a produção solar estimada com o perfil de consumo de uma casa típica. Para cada cenário de potência, calcula:

- a energia produzida, autoconsumida e injetada na rede;
- a poupança anual;
- o tempo de retorno do investimento.

## 2. Fontes de dados

| Fonte | Tipo | Formato | Ficheiro / origem |
|---|---|---|---|
| PVGIS (Comissão Europeia) | API REST | JSON | `https://re.jrc.ec.europa.eu/api/v5_3/seriescalc` |
| E-REDES — Perfis de Consumo 2026 | Ficheiro local | XLSX | `data/input/perfis_eredes_2026.xlsx` |
| Cenários de investimento | Ficheiro local | CSV | `data/input/cenarios.csv` |

O ficheiro `cenarios.csv` tem, de propósito, um cenário repetido (B) e um cenário sem potência (D). Servem para demonstrar a limpeza de dados.

## 3. Processo ETL

| Ficheiro | Fase | O que faz |
|---|---|---|
| `dataintegration/01_extrair_pvgis.ktr` | Extração | Chama a API do PVGIS e lê a resposta JSON em dois níveis. Extrai a data e a hora de cada registo com uma expressão regular. |
| `dataintegration/02_extrair_perfis_eredes.ktr` | Extração | Lê do Excel da E-REDES o perfil de consumo, de 15 em 15 minutos, e descarta as linhas vazias. |
| `dataintegration/03_transformar.ktr` | Transformação e carga | Converte a hora UTC do PVGIS para a hora de Lisboa e agrega os dados por hora. Junta a produção ao consumo e limpa os cenários: rejeita os incompletos e remove os duplicados. Calcula, hora a hora, o autoconsumo, o excedente e a compra à rede. Resume os resultados por cenário e por mês e exporta-os para CSV, JSON, XML e Excel. |
| `dataintegration/job_principal.kjb` | Orquestração | Executa as três transformações por ordem e grava o log em `logs/execucao.log`. Se alguma falhar, regista o erro e aborta. |

## 4. Estrutura e descrição dos ficheiros

```
├── README.md
├── doc/
│   └── 27965_doc.pdf                 Relatório
├── dataintegration/                  Transformações (.ktr) e job (.kjb)
├── data/
│   ├── input/
│   │   ├── perfis_eredes_2026.xlsx   Perfis oficiais de consumo (E-REDES)
│   │   └── cenarios.csv              Cenários de potência, custo e tarifário
│   └── output/                       Ficheiros produzidos pelo ETL
├── logs/                             Log de execução do job
└── src/                              Sem código: toda a lógica está no PDI
```

Ficheiros produzidos em `data/output/`:

| Ficheiro | Linhas | Conteúdo |
|---|---|---|
| `01_pvgis_horario.csv` | 8760 | Produção horária de 1 kWp em Braga (hora UTC) |
| `02_perfis_15min.csv` | 35 040 | Perfil de consumo de 15 em 15 minutos |
| `03_balanco_horario.csv` | 26 277 | Produção, consumo, autoconsumo, excedente e compra à rede, por hora e cenário |
| `03_resumo_cenarios.csv` | 3 | Totais anuais, poupança e retorno por cenário |
| `03_resumo_mensal.csv` | 36 | Totais mensais por cenário |
| `04_resumo_cenarios.json` | 3 | Resumo anual em JSON |
| `04_resumo_mensal.xml` | 36 | Resumo mensal em XML |
| `04_relatorio_cenarios.xlsx` | 3 | Resumo anual em Excel |

O prefixo indica a etapa: 01 e 02 são extração, 03 é transformação e 04 são as exportações finais.

## 5. Resultados

| Cenário | Potência | Produção | Autoconsumo | Poupança anual | Retorno |
|---|---|---|---|---|---|
| A | 2 kWp | 2845 kWh | 1466 kWh (52 %) | 362 € | 7,7 anos |
| B | 3 kWp | 4267 kWh | 1586 kWh (37 %) | 451 € | 8,4 anos |
| C | 4 kWp | 5689 kWh | 1661 kWh (29 %) | 534 € | 8,8 anos |

O sistema mais pequeno é o que se paga mais depressa. Cada kWh autoconsumido poupa 0,20 €, mas cada kWh vendido à rede rende só 0,05 €. Por isso, cada kWp a mais vale cada vez menos.

## 6. Como executar

**Requisitos**
- Pentaho Data Integration 10.2 CE
- Java 21, com a variável `JAVA_HOME` definida
- Ligação à Internet (para a API do PVGIS)

**No Spoon**
1. Abrir `dataintegration/job_principal.kjb` (File → Open).
2. Executar (F9 → Run).
3. Os resultados ficam em `data/output/` e o log em `logs/execucao.log`.

**Na linha de comandos (Windows)**
```
cd <pasta do PDI>\data-integration
Kitchen.bat /file:"<pasta do projeto>\dataintegration\job_principal.kjb" /level:Basic
```

Deve executar-se sempre o job, e não as transformações soltas, porque a 03 lê os ficheiros criados pela 01 e pela 02. Todos os caminhos são relativos à localização dos ficheiros `.ktr` e `.kjb`, por isso o projeto funciona em qualquer pasta.

## 7. Simplificações assumidas

- A produção é estimada pelo PVGIS para um ano real (2023) e o consumo usa os perfis oficiais de 2026. As duas séries são cruzadas pela chave mês-dia-hora, num "ano típico".
- O consumo vem de um perfil-tipo (BTN C) escalado para 4000 kWh/ano, e não de um contador real.
- Na hora de Lisboa, o ano tem 8759 horas distintas: a hora que desaparece em março não existe, e as duas ocorrências da hora repetida em outubro são somadas.
- Os cenários não incluem bateria.
- Os preços de compra (0,20 €/kWh) e de venda (0,05 €/kWh) são valores de referência fixos.

## 8. Fontes e atribuições

- PVGIS © União Europeia, Joint Research Centre
- E-REDES — Perfis de Consumo e Injeção 2026 (CC BY 4.0)
