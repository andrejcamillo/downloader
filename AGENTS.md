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
```

---

# 10. Data e Infrastructure

A camada Data/Infrastructure encapsula as implementações concretas e integrações externas:

- implementações de Repositories definidas pelo Domain;
- clientes e adaptadores de processos externos (FFmpeg, yt-dlp);
- acesso ao sistema de arquivos local e storage;
- serviços de rede e APIs externas.

### Regras desta camada:
- Detalhes de processos, comandos e filesystem **não devem vazar** para Presentation ou Domain;
- Erros de processos externos ou filesystem devem ser mapeados para exceções/resultados tipados e expressivos de domínio;
- Liberação explícita de recursos e encerramento de processos ao finalizar ou cancelar operações.

---

# 11. Downloads e Processamento de Mídia (yt-dlp e FFmpeg)

Operações de download e processamento de mídia são assíncronas e potencialmente longas.

### Regras essenciais:
- **Não bloquear a interface**: Toda execução de ferramentas externas deve rodar em background/isolates/streams assíncronas;
- **Estado real da operação**: Representar de forma confiável e em tempo real os estados de início, progresso, conclusão, erro e cancelamento. Nunca informar conclusão antes do arquivo estar 100% gravado e validado;
- **Cancelamento e processos órfãos**: Tratar interrupção e cancelamento com o encerramento explícito dos processos filhos (`SIGTERM`/`kill`), evitando deixar processos externos órfãos rodando em segundo plano;
- **Arquivos temporários e limpeza**: Arquivos parciais e temporários gerados durante o download ou conversão devem ser limpos após conclusão ou falha;
- **Concorrência e limites de recursos**: Evitar concorrência descontrolada de downloads e conversões simultâneas de FFmpeg/yt-dlp para não exaurir CPU, RAM ou largura de banda;
- **Metadados e integridade**: Preservar metadados, codecs e integridade dos arquivos conforme solicitado no requisito.

---

# 12. Sistema de Arquivos e Compatibilidade Multiplataforma

O projeto roda em múltiplas plataformas (Windows, Linux, Android):

- **Caminhos seguros e portáveis**: Nunca utilize caminhos absolutos hardcoded ou específicos da máquina de desenvolvimento;
- **APIs de plataforma**: Utilize `path_provider` ou abstrações de storage apropriadas para a plataforma;
- **Sanitização de nomes de arquivos**: Sanitize nomes de arquivos removendo caracteres inválidos ou reservados (`/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`);
- **Permissões e diretórios**: Verifique e crie diretórios de destino se não existirem, tratando falhas de permissão de escrita ou espaço em disco insuficiente;
- **Mover entre unidades**: Ao mover arquivos entre volumes/drives diferentes, use estratégia com fallback de cópia + deleção quando `rename` falhar.

---

# 13. Segurança e Execução de Comandos

A segurança é prioridade máxima:

- **Proibida concatenação de comandos em shell**: Nunca monte strings de comando concatenando entradas não validadas do usuário (ex: `sh -c "$cmd $url"`). Utilize APIs seguras como `Process.start` ou `Process.run` passando a lista de argumentos como lista de strings (`List<String>`);
- **Sanitização rigorosa de entradas**: URLs, nomes de pastas e títulos fornecidos pelo usuário ou pela web devem ser validados e sanitizados antes do repasse aos binários externos;
- **Proteção de credenciais**: Nunca exponha segredos, tokens, cookies de sessão ou credenciais em código, repositório ou logs da aplicação.

---

# 14. Validação e Testes

Antes de concluir qualquer tarefa ou entrega, as ferramentas de validação do projeto devem ser executadas e estar 100% limpas:

```bash
# Formatação de código
dart format .

# Análise estática (linter e tipagem)
flutter analyze

# Suite de testes
flutter test
```

### Critérios de teste:
- Testes unitários para parsers (stdout do yt-dlp, mappers de playlist/m3u, sanitizadores de caminho);
- Testes de regras de negócio, use cases e ViewModels com controle de concorrência e mocks de infraestrutura;
- Validar cenários de erro, cancelamento e falha de ferramentas externas;
- Nenhuma alteração é considerada pronta apenas porque compila.

---

# 15. Agentes e Regras de Desenvolvimento

### Tech Lead
- Responsável por arquitetura, planejamento técnico, decomposição de tarefas e orientação técnica;
- Fonte da verdade absoluta: este `AGENTS.md`;
- Produz plano técnico antes de qualquer alteração significativa, preservando a arquitetura existente.

### Builder e Builder Fallback
- Responsáveis pela implementação de código, testes e validação;
- Seguem estritamente as decisões do `AGENTS.md` e o plano do Tech Lead;
- Em caso de indisponibilidade ou falha do Builder principal, o **Builder Fallback** assume a tarefa a partir do estado atual sem reiniciar do zero;
- Respeitam rigorosamente as regras de segurança, execução de processos externos (`Process.start` com `List<String>`), cancelamento de subprocessos e limpeza de temporários;
- Validação mandatória: `dart format .`, `flutter analyze` sem advertências e `flutter test` com todos os testes passando.

### Reviewer
- Auditoria técnica independente, crítica e rigorosa;
- **NÃO modifica arquivos, NÃO commita e NÃO corrige código**;
- Checklist prioritário:
  1. **Segurança**: Comandos de sistema construídos de forma insegura, injeção de argumentos, credenciais/cookies vazando em logs;
  2. **Processos e Recursos**: Processos órfãos de yt-dlp/ffmpeg após fechamento/cancelamento, falta de limpeza de arquivos temporários, concorrência descontrolada;
  3. **Arquitetura e Contratos**: Camadas respeitadas (`Presentation` → `Domain` → `Data`), UI sem acoplamento a binários externos;
  4. **Multiplataforma**: Caminhos inválidos em Windows/Linux, rename entre diferentes drives;
  5. **Qualidade e Testes**: `flutter analyze` limpo e cobertura adequada de testes para casos de sucesso e erro;
- Emite relatório com severidades (`CRÍTICO`, `ALTO`, `MÉDIO`, `BAIXO`) e veredito final (`APROVADO`, `APROVADO COM OBSERVAÇÕES`, `REQUER CORREÇÕES`, `BLOQUEADO`).