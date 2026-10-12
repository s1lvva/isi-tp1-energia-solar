# Vale a pena pôr painéis?
### ETL com dados abertos para avaliar o autoconsumo solar doméstico

| | |
|---|---|
| **Unidade Curricular** | Integração de Sistemas de Informação (ISI) |
| **Curso** | Licenciatura em Engenharia de Sistemas Informáticos — ESTi / IPCA |
| **Ano letivo** | 2026/27 |
| **Trabalho** | Trabalho Prático I — Processos de ETL |
| **Aluno** | _André Silva_ — n.º _a27965_ |
| **Docentes** | Luís Ferreira e Óscar Ribeiro |
| **Entrega** | 22 de outubro de 2026 |

---

## 1. Problema

Uma família em Braga pondera instalar painéis solares. A decisão depende de dados espalhados por sistemas que não falam entre si: o potencial solar do local, o perfil de consumo da casa, a meteorologia e o preço da eletricidade em cada quarto de hora. Nenhuma destas fontes, sozinha, responde às perguntas que interessam:

1. **Quanto produziria?** Produção estimada de uma instalação com a potência, a inclinação e a orientação definidas.
2. **Quanto pouparia?** Produção cruzada com o perfil de consumo da casa: energia autoconsumida vs. injetada na rede, valorizada ao preço de cada quarto de hora.
3. **Compensa?** Tempo de retorno do investimento para vários cenários (potência, com e sem bateria) e recomendação do melhor.

O trabalho integra estas fontes num processo de ETL completo: recolha (E), transformação (T) e carregamento, exportação e notificação (L). Todas as fontes são **dados abertos**, pelo que o processo é reproduzível por qualquer pessoa.

## 2. Arquitetura

```
 FONTES (E)                            TRANSFORMAÇÃO (T)               DESTINOS (L)
 ────────────────────────────          ────────────────────           ──────────────────────
 PVGIS (API)             JSON/CSV ─┐                                 ┌─► PostgreSQL (data mart)
 E-REDES perfis 2026     XLSX     ─┤                                 ├─► Exportação CSV/JSON/XML
 E-REDES Open Data (API) JSON     ─┼──►  Pentaho Data Integration ───┼─► Relatório PDF
 OMIE (ficheiros)        CSV      ─┤     (transformações + jobs)     ├─► Alertas por email
 Open-Meteo / IPMA (API) JSON     ─┤                                 └─► Dashboard Grafana
 Cenários                YAML     ─┘
        ▲
 Node-RED ── "inversor virtual" ── MQTT (Mosquitto) ── MongoDB (eventos em bruto)
```

## 3. Fontes de dados

| Fonte | Tipo | Formato | O que traz |
|---|---|---|---|
| [PVGIS](https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis/getting-started-pvgis/api-non-interactive-service_en) (Comissão Europeia) | API REST, sem chave | JSON / CSV | Produção fotovoltaica horária estimada por local, potência, inclinação e orientação |
| [E-REDES — Perfis de Consumo e Injeção 2026](https://www.e-redes.pt/en/consumption-and-loss-profiles) | Ficheiro | XLSX | Perfis oficiais de 15 em 15 min (BTN A/B/C, produção fotovoltaica, autoconsumo), normalizados para somar 1000 |
| [E-REDES Open Data](https://e-redes.opendatasoft.com/) | API REST | JSON / CSV | Consumo horário real agregado por código postal (ex.: 4700, Braga) |
| [OMIE](https://www.omie.es/) | Ficheiros públicos | CSV | Preço do mercado diário por quarto de hora |
| [Open-Meteo](https://open-meteo.com/) | API REST, sem chave | JSON | Irradiância no plano dos painéis, previsão e histórico |
| [IPMA](https://api.ipma.pt/) | API REST, sem chave | JSON | Observações horárias da estação mais próxima |
| `config/config.yaml` | Configuração | YAML | Local, cenários a comparar, tarifário, custos, limiares |
| Node-RED | Streaming MQTT | JSON | "Inversor virtual": produção estimada ao minuto a partir da irradiância atual |

## 4. Tecnologias

- **Pentaho Data Integration (Kettle)** — transformações e jobs de orquestração
- **Node-RED** + **Eclipse Mosquitto** — recolha contínua e publicação MQTT
- **PostgreSQL** — data mart de destino
- **MongoDB** — armazenamento dos eventos em bruto
- **Grafana** — dashboard
- **Docker Compose** — ambiente reprodutível

## 5. Estrutura do repositório

```
├── config/                 Cenários e parâmetros (YAML)
├── data/
│   ├── raw/                Downloads originais das fontes (não versionados — volume)
│   ├── samples/            Amostras pequenas para demonstração
│   ├── processed/          Dados intermédios
│   └── output/             Ficheiros exportados (CSV, JSON, XML, PDF)
├── etl/
│   ├── transformations/    Transformações do PDI (.ktr)
│   └── jobs/               Jobs do PDI (.kjb)
├── node-red/               Flows do Node-RED (.json)
├── sql/                    Scripts SQL e dumps
├── dashboards/grafana/     Dashboards exportados
├── docker/                 Configuração dos serviços
├── docs/
│   ├── relatorio/          Relatório final
│   └── diagramas/          Diagramas das transformações e jobs
└── logs/                   Logs de execução
```

## 6. Como executar

1. Copiar `.env.example` para `.env` e definir as palavras-passe.
2. Arrancar os serviços:
   ```bash
   docker compose up -d
   ```
3. Serviços disponíveis:

   | Serviço | Endereço |
   |---|---|
   | PostgreSQL | `localhost:5432` |
   | MongoDB | `localhost:27017` |
   | Mosquitto (MQTT) | `localhost:1883` |
   | Node-RED | http://localhost:1880 |
   | Grafana | http://localhost:3000 |

4. Ajustar os cenários em `config/config.yaml`.
5. Abrir o PDI (Spoon) e executar o job principal em `etl/jobs/`.

## 7. Estado do trabalho

- [x] Tema e plataformas definidos
- [x] Estrutura do repositório e ambiente Docker
- [ ] **Fase 1 (E)** — leitura de todas as fontes
- [ ] **Fase 2 (T)** — limpeza, validação, normalização, joins, agregações
- [ ] **Fase 3 (L)** — data mart, exportações, alertas, dashboard
- [ ] Job orquestrador com logs
- [ ] Relatório
- [ ] Vídeo de demonstração

## 8. Limitações

- A produção vem de um modelo (PVGIS) e não de uma instalação real. O "inversor virtual" do Node-RED é um simulador.
- O consumo da casa vem de perfis-tipo oficiais escalados por um consumo anual definido nos cenários, não de um contador real.
- Os resultados são estimativas para apoio à decisão e não substituem um estudo técnico.

## 9. Atribuições

- Produção fotovoltaica: PVGIS © União Europeia, Joint Research Centre
- Perfis de consumo e dados de consumo: E-REDES — Portal Open Data (CC BY 4.0) #PortalOpenData_E_REDES
- Dados meteorológicos: [Open-Meteo.com](https://open-meteo.com/) (CC BY 4.0)
- Observações meteorológicas: © IPMA — Instituto Português do Mar e da Atmosfera
- Preços de mercado: OMIE — Operador del Mercado Ibérico de Energía
