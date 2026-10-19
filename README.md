# Vale a pena pôr painéis?
### ETL com dados abertos para avaliar o autoconsumo solar doméstico

| | |
|---|---|
| **Aluno** | _Nome_ — n.º _XXXXX_ |
| **Unidade Curricular** | Integração de Sistemas de Informação (ISI) |
| **Curso** | Licenciatura em Engenharia de Sistemas Informáticos — IPCA |
| **Ano letivo** | 2026/27 — Trabalho Prático I |
| **Docentes** | Luís Ferreira e Óscar Ribeiro |
| **Ferramenta** | Pentaho Data Integration (Kettle) 10.2 CE |

**🎬 Vídeo de demonstração:** _(colocar aqui o link)_

---

## 1. Objetivo

Uma família em Braga, com um consumo anual de 4000 kWh, pondera instalar painéis solares. O processo de ETL cruza a produção solar estimada com o perfil de consumo de uma casa típica, hora a hora, e calcula para vários cenários de potência:

- a energia produzida, autoconsumida e injetada na rede;
- a poupança anual;
- o tempo de retorno do investimento.

## 2. Fontes de dados (Fase 1 — Extração)

| Fonte | Tipo | Formato | Ficheiro / origem |
|---|---|---|---|
| PVGIS (Comissão Europeia) | API REST | JSON | `https://re.jrc.ec.europa.eu/api/v5_3/seriescalc` |
| E-REDES — Perfis de Consumo 2026 | Ficheiro local | XLSX | `data/input/perfis_eredes_2026.xlsx` |
| Cenários de investimento | Ficheiro local | CSV | `data/input/cenarios.csv` |

## 3. Processo ETL

| Ficheiro | Fase | O que faz |
|---|---|---|
| `dataintegration/01_extrair_pvgis.ktr` | E | Chama a API do PVGIS, valida a resposta HTTP, lê o JSON em dois níveis e extrai a data/hora com uma expressão regular |
| `dataintegration/02_extrair_perfis_eredes.ktr` | E | Lê o perfil de consumo de 15 em 15 minutos do Excel da E-REDES |
| `dataintegration/03_transformar.ktr` | T | Converte UTC → hora de Lisboa, agrega por hora, junta produção e consumo, cruza com os cenários e calcula autoconsumo, poupança e retorno |
| `dataintegration/04_exportar.ktr` | L | Exporta os resultados para CSV, JSON, XML e Excel |
| `dataintegration/job_principal.kjb` | — | Orquestra as quatro transformações por ordem, regista logs e trata erros |

## 4. Estrutura e descrição dos ficheiros

```
├── README.md
├── doc/
│   ├── XXXXX_doc.pdf             Relatório final
│   └── diagramas/                Capturas das transformações e do job
├── dataintegration/              Transformações (.ktr) e job (.kjb)
├── data/
│   ├── input/
│   │   ├── perfis_eredes_2026.xlsx   Perfis oficiais de consumo (E-REDES)
│   │   └── cenarios.csv              Cenários de potência, custo e tarifário
│   └── output/                   Ficheiros produzidos pelo ETL
└── logs/                         Logs de execução do job
```

Ficheiros produzidos em `data/output/`:

| Ficheiro | Conteúdo |
|---|---|
| `01_pvgis_horario.csv` | Produção horária de 1 kWp em Braga (8760 linhas) |
| `02_perfis_15min.csv` | Perfil de consumo de 15 em 15 minutos |
| `03_balanco_horario.csv` | Produção, consumo, autoconsumo e excedente por hora e cenário |
| `03_resumo_cenarios.csv` | Totais anuais, poupança e retorno por cenário |
| `04_resumo_cenarios.json` | O mesmo resumo em JSON |
| `04_resumo_mensal.xml` | Totais mensais por cenário em XML |
| `04_relatorio_cenarios.xlsx` | Resumo em Excel |

## 5. Como executar

**Requisitos**
- Pentaho Data Integration 10.2 CE
- Java 21, com a variável `JAVA_HOME` definida
- Ligação à Internet (para a API do PVGIS)

**No Spoon**
1. Abrir `dataintegration/job_principal.kjb` (File → Open).
2. Executar (F9 → Run).
3. Os resultados ficam em `data/output/` e o log em `logs/`.

**Na linha de comandos (Windows)**
```
cd <pasta do PDI>\data-integration
Kitchen.bat /file:"<pasta do projeto>\dataintegration\job_principal.kjb" /level:Basic
```

Todos os caminhos são relativos à localização dos ficheiros `.ktr`, por isso o projeto funciona em qualquer pasta.

## 6. Simplificações assumidas

- A produção é estimada pelo PVGIS para um ano real (2023) e o consumo usa os perfis oficiais de 2026. As duas séries são cruzadas por mês, dia e hora, num "ano típico".
- O consumo vem de um perfil-tipo (BTN C) escalado para 4000 kWh/ano, e não de um contador real.
- Os cenários não incluem bateria.
- Os preços de compra e venda são valores de referência fixos.

## 7. Fontes e atribuições

- PVGIS © União Europeia, Joint Research Centre
- E-REDES — Perfis de Consumo e Injeção 2026 (CC BY 4.0)
