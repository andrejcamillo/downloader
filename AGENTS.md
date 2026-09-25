# Music Downloader — AGENTS.md

## 1. Objetivo e Visão Geral

O Music Downloader é uma aplicação Flutter destinada ao download e
processamento de conteúdo de mídia, com foco em música.

O projeto teve uma implementação inicial rápida e não possui atualmente uma
arquitetura formal consolidada.

O código existente deve ser considerado código legado em processo de
organização e refatoração.

O objetivo deste projeto é evoluir a aplicação para uma estrutura:

- organizada;
- testável;
- sustentável;
- multiplataforma quando aplicável;
- com baixo acoplamento;
- com responsabilidades bem definidas;
- resistente a mudanças de dependências e APIs;
- simples o suficiente para não criar complexidade artificial.

A arquitetura deve servir ao aplicativo.

Não criar abstrações, camadas ou padrões apenas para cumprir uma regra
arquitetural.

---

## 2. Estado Atual e Refatoração

O código existente foi desenvolvido inicialmente sem uma arquitetura formal.

Portanto, o projeto pode conter:

- lógica de interface misturada com lógica de negócio;
- acesso direto a serviços externos;
- chamadas de processos externos dentro da UI;
- gerenciamento de arquivos espalhado;
- dependências diretamente utilizadas por Widgets;
- classes com múltiplas responsabilidades;
- código incompatível com versões atuais do Flutter ou Dart;
- APIs ou métodos deprecated;
- estruturas que não seguem a arquitetura-alvo.

Isso é esperado.

### Regra principal de migração

O projeto NÃO deve ser reescrito integralmente apenas para adequação
arquitetural.

A refatoração deve ser incremental.

Ao trabalhar em uma funcionalidade existente:

1. investigar o código atual;
2. identificar suas responsabilidades;
3. identificar dependências;
4. identificar consumidores;
5. avaliar problemas de compatibilidade;
6. definir a menor refatoração necessária;
7. migrar a área afetada para a arquitetura-alvo;
8. preservar o comportamento existente sempre que possível;
9. testar a alteração.

Novas funcionalidades devem seguir a arquitetura definida neste documento.

Código legado não precisa ser reorganizado simplesmente porque está fora da
estrutura ideal.

Quando uma funcionalidade legada precisar sofrer alterações relevantes, o
Tech Lead deve avaliar se a oportunidade justifica sua migração.

---

## 3. Decisões Arquiteturais

As decisões explicitamente estabelecidas neste documento são decisões do
projeto.

Os agentes não devem reavaliá-las ou substituí-las apenas por preferência
pessoal.

Uma decisão pode ser reconsiderada quando existir:

- novo requisito;
- limitação técnica real;
- incompatibilidade;
- problema de manutenção;
- problema de segurança;
- problema de desempenho;
- necessidade multiplataforma;
- mudança significativa das tecnologias utilizadas;
- inconsistência arquitetural real;
- autorização explícita.

Quando uma decisão existente precisar ser alterada, a alteração deve ser
identificada e justificada.

---

# 4. Stack Tecnológica

A aplicação utiliza:

- Flutter;
- Dart;
- Material Design;
- Null Safety.

A aplicação deve permanecer, sempre que tecnicamente possível, independente
de uma plataforma específica.

O projeto pode utilizar recursos específicos de:

- Windows;
- Linux;
- Android;
- outras plataformas suportadas;

porém detalhes específicos de plataforma devem permanecer isolados sempre
que possível.

Não assumir que um comportamento existente em uma plataforma funcionará
automaticamente em outra.

---

# 5. Arquitetura

O projeto deve evoluir para:

- Clean Architecture;
- MVVM na Presentation;
- Feature-first;
- Repository Pattern quando houver necessidade de abstração de acesso a
  dados ou serviços;
- inversão de dependências.

A arquitetura deve ser aplicada de forma pragmática.

Não criar camadas artificiais.

Uma funcionalidade simples pode possuir menos componentes quando isso for
suficiente.

Por exemplo, não criar automaticamente:

- Use Case;
- Repository;
- DataSource;
- Model;
- Mapper;
- Service;

se a responsabilidade não justificar esses componentes.

---

# 6. Direção das Dependências

A direção preferencial é:

Presentation
    ↓
Domain
    ↓
abstrações

Data / Infrastructure
    ↓
implementações

O Domain não deve depender de:

- Flutter;
- Widgets;
- FFmpeg;
- sistema operacional;
- filesystem;
- HTTP;
- ferramentas externas;
- bibliotecas específicas de infraestrutura.

O objetivo é permitir que regras e comportamentos centrais sejam testados sem
necessidade de executar Flutter, FFmpeg ou ferramentas externas.

---

# 7. Feature-first

A aplicação deve ser organizada principalmente por funcionalidade.

Estrutura conceitual:

lib/
├── core/
└── features/
    ├── <feature>/
    │   ├── presentation/
    │   ├── domain/
    │   └── data/
    └── ...

A estrutura exata deve ser definida pelo Tech Lead após analisar as
funcionalidades reais do aplicativo.

Não criar uma estrutura de features artificial apenas para preencher
diretórios.

O `core/` deve conter somente funcionalidades realmente compartilhadas entre
múltiplas features.

Não utilizar `core/` como depósito genérico para qualquer código que não tenha
um local definido.

---

# 8. Presentation — MVVM

A Presentation pertence ao Flutter.

Responsabilidades:

- apresentação;
- interação do usuário;
- estado da interface;
- navegação;
- loading;
- sucesso;
- erro;
- cancelamento;
- atualização visual de progresso.

Fluxo conceitual:

View
  ↓
ViewModel
  ↓
Use Case
  ↓
Repository / abstração

### View

A View deve:

- apresentar informações;
- receber interações;
- observar o estado;
- delegar operações ao ViewModel.

A View não deve conter regras de negócio ou lógica de infraestrutura.

Evitar:

- execução direta de processos externos;
- manipulação complexa de arquivos;
- chamadas diretas a APIs externas;
- construção de comandos FFmpeg;
- regras de download.

### ViewModel

O ViewModel deve:

- controlar o estado da tela;
- coordenar ações da interface;
- executar Use Cases;
- transformar resultados em estados de apresentação;
- controlar loading;
- apresentar erros;
- acompanhar progresso;
- tratar cancelamento quando aplicável.

O ViewModel não deve conhecer detalhes de implementação do FFmpeg,
filesystem ou outras ferramentas externas.

---

# 9. Domain

O Domain contém as regras e abstrações centrais da aplicação.

Pode conter:

- Entities;
- Value Objects quando realmente necessários;
- Use Cases;
- Repository Contracts;
- contratos de serviços essenciais ao domínio.

O Domain não deve depender de detalhes de infraestrutura.

Exemplo:

```text
Domain
└── repositories
    └── downloader_repository.dart