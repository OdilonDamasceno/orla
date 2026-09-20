# Diretrizes para agentes — Orla

## Escopo e objetivo

Estas instruções se aplicam a todo o repositório. Respeite instruções mais específicas em subdiretórios e os pedidos explícitos do usuário. Comunique decisões e resultados em português brasileiro.

O Orla é uma interface de desktop construída com Quickshell, Qt Quick/QML e integração com Wayland/Hyprland. Sua identidade combina a estrutura do **Material Design 3 (MD3)** com acabamento visual inspirado na **Apple**: hierarquia clara, superfícies refinadas, composição leve e movimento discreto.

As regras abaixo são decisões de design deste projeto, não uma declaração de conformidade integral com as plataformas Google ou Apple. Acessibilidade, legibilidade e comportamento previsível têm prioridade sobre efeitos decorativos.

## Estrutura do projeto

- `shell.qml`: entrada da shell, serviços e composição das instâncias por monitor.
- `surfaces/`: superfícies Wayland e composição das janelas visíveis.
- `components/`: primitivas visuais reutilizáveis e sem estado de domínio.
- `widgets/`: launcher, painéis, notificações e controles de domínio.
- `services/`: lógica sem interface, processos e ciclos de vida auxiliares.
- `singletons/Theme.qml`: tokens visuais compartilhados derivados da configuração validada.
- `singletons/Config.qml`: carregamento, defaults e validação das preferências do usuário.
- `singletons/I18n.qml`: traduções e formatação localizada.
- `singletons/qmldir`: registro dos singletons.
- `icons/`: recursos vetoriais locais.
- `docs/assets/`: imagens locais referenciadas pela documentação.
- `config.example.json`: esquema de referência e defaults da configuração externa.
- `README.md` e `README.en.md`: documentação pública equivalente em português e inglês.
- `flake.nix` e `flake.lock`: ambiente de desenvolvimento e dependências Nix.

Leia os componentes envolvidos antes de editar. Preserve alterações locais que não pertencem à tarefa; não reverta, remova ou recrie arquivos do usuário para facilitar a implementação.

## Linguagem visual: Material Design 3 + Apple

### Princípio de combinação

Use MD3 para os papéis semânticos de cor, hierarquia de componentes e estados de interação. Use a inspiração Apple para proporção, alinhamento, agrupamento, profundidade sutil e continuidade das transições. Evite misturar estilos diferentes para controles com a mesma função.

Priorize superfícies neutras, um destaque cromático controlado, cantos arredondados coerentes e espaço suficiente entre grupos. A interface deve parecer parte de uma única shell, inclusive em launcher, barra, menus e notificações.

### Tokens e cores

- Centralize tokens reutilizados em `Theme.qml`: cores, espaçamentos, raios, tipografia, durações e opacidades. Preferências configuráveis são validadas por `Config.qml`; componentes visuais não devem ler o JSON diretamente.
- Prefira papéis semânticos como `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `surface`, `surfaceContainer`, `onSurface`, `onSurfaceVariant`, `outline` e `error`, com pares de conteúdo e superfície compatíveis.
- Evite repetir valores hexadecimais ou medidas em vários componentes. Migre valores existentes apenas no escopo necessário à alteração.
- Preserve a aparência escura atual como referência inicial. Se adicionar tema claro, use os mesmos papéis semânticos e verifique os dois temas.
- Reserve a cor de destaque para ações principais, seleção e foco. Não use apenas cor para comunicar erro, estado ou seleção.

### Espaçamento, formas e densidade

- Use uma escala de espaçamento baseada em 4 unidades lógicas: 4, 8, 12, 16, 24 e 32. Escolha valores pela hierarquia do conteúdo.
- Use raios consistentes por categoria de componente. Como ponto de partida: 8 para elementos pequenos, 12–16 para controles e cartões, 24–32 para painéis; cápsulas usam metade da altura.
- Preserve a densidade compacta da barra, atualmente com 32 unidades de altura. Não aumente toda a interface para reproduzir proporções de uma interface móvel.
- Separe tamanho visual de área interativa. Em painéis, prefira alvos de pelo menos 40 × 40 unidades lógicas; em interfaces destinadas a toque, adote 48 × 48. Na barra compacta, amplie o alvo dentro do espaço disponível sem sobrepor controles.
- Alinhe ícones, textos e grupos por referências visuais consistentes. Evite compensações arbitrárias e espaçamentos negativos novos sem justificativa clara.

### Tipografia e ícones

- Use `Theme.fontFamily`, atualmente `Sunghyun Sans`. Não introduza fontes Apple ou novas dependências de fontes sem necessidade explícita.
- Defina papéis tipográficos reutilizáveis: rótulo, corpo, subtítulo e título. Diferencie hierarquia com tamanho, peso e cor; evite excesso de pesos ou textos muito pequenos.
- Prefira texto de conteúdo com 14–16 unidades lógicas e rótulos compactos com 12–13, ajustando ao contexto e à legibilidade.
- Reutilize os SVGs em `icons/` e componentes de ícone existentes. Mantenha espessura, tamanho óptico e linguagem visual consistentes; não misture emojis com ícones de interface.
- Trate textos longos com quebra ou elisão deliberada, preservando acesso ao conteúdo completo quando necessário.

### Superfícies e acabamento Apple

- Use profundidade para separar camadas: superfície tonal, borda discreta e sombra suave quando apropriado.
- Transparência, blur e aparência de vidro são opcionais. Use-os somente quando ajudarem a separar o conteúdo e houver suporte no ambiente.
- Garanta uma superfície de fallback legível sem blur e com diferentes papéis de parede. Não deixe a leitura depender da imagem de fundo.
- Evite brilho intenso, gradientes decorativos excessivos, múltiplas sombras e contornos competindo com o conteúdo.
- Reutilize `GradientBorder.qml` quando pertinente; não imponha bordas de vidro a todos os controles.

### Interação, movimento e acessibilidade

- Implemente estados normal, hover, pressionado, foco, selecionado e desabilitado conforme o controle. O foco de teclado deve ser visível e distinto do hover.
- Prefira controles de Qt Quick Controls para preservar semântica, teclado e comportamento. Forneça nomes acessíveis, especialmente em botões que exibem somente ícones.
- Permita navegação por teclado, ativação por Enter/Espaço quando aplicável e fechamento de superfícies transitórias por Escape. Libere o foco exclusivo ao fechar overlays.
- Use como metas de contraste 4,5:1 para texto comum e 3:1 para texto grande e indicadores essenciais; confira o resultado sobre a superfície efetiva, inclusive com transparência.
- Use transições curtas como referência do projeto: 120–180 ms para feedback e 180–280 ms para abertura ou mudança de composição. Prefira desaceleração suave e evite elasticidade excessiva.
- Anime propriedades específicas. Evite `Behavior` genérico que provoque animações durante inicialização ou atualizações frequentes de dados.
- Para movimento reduzido, quando disponível ou implementado, elimine deslocamentos e escalas dispensáveis, mantendo o feedback de estado.
- Inclua estados vazio, carregando, indisponível e erro quando relevantes. Evite alterações de tamanho que desloquem controles durante a interação.

## Configuração externa

- O arquivo opcional do usuário é `$XDG_CONFIG_HOME/orla/config.json`, com fallback para `~/.config/orla/config.json`. Não escreva ou substitua esse arquivo automaticamente.
- `Config.qml` é a única fronteira de leitura e validação. Exponha propriedades derivadas e tipadas para o restante da shell; não espalhe acesso ao adapter JSON pelos componentes.
- Preserve defaults funcionais quando o arquivo não existir, estiver incompleto ou contiver um valor fora do domínio aceito. Limite intervalos, quantidades e durações para evitar polling excessivo ou geometria inviável.
- Mantenha `config.example.json`, `Config.qml`, `README.md` e `README.en.md` sincronizados ao adicionar, renomear ou remover uma opção.
- Expanda `~/` somente em propriedades que representam caminhos. Não aceite comandos arbitrários vindos da configuração nem monte comandos por interpolação insegura.
- Mantenha preferências em `$XDG_CONFIG_HOME` e estado interno em `$XDG_STATE_HOME`. Dados como contadores de uso não pertencem ao arquivo de preferências.
- Mudanças de configuração devem atualizar bindings existentes sem recriar superfícies desnecessariamente. Quando houver observação de arquivo, preserve o último estado válido diante de falhas transitórias.
- A Live Activity é genérica: use nomes como `LiveMatchService` e `FootballLiveActivity`. Não volte a acoplar serviços ou propriedades a um clube específico; o time padrão é apenas um default configurável.

## Convenções de implementação

- Use indentação de quatro espaços em QML, nomes de componentes em `PascalCase` e propriedades/funções em `camelCase`. Siga o estilo do arquivo ao fazer alterações pequenas.
- Prefira propriedades tipadas, `readonly property` para valores derivados e `required property` para dependências obrigatórias. Use `id: root` quando adequado.
- Mantenha bindings declarativos; evite atribuições imperativas que os quebrem sem intenção. Extraia componentes quando houver reutilização real ou responsabilidade independente.
- Use `RowLayout`, `ColumnLayout` e propriedades `Layout.*` em composições adaptáveis. Não combine anchors e controle de geometria pelo layout no mesmo item.
- Respeite ciclo de vida e APIs de Quickshell. Trate monitor ausente, serviço indisponível e valores nulos antes de acessar suas propriedades.
- Preserve funcionamento em múltiplos monitores, escala fracionária e diferentes resoluções. Limite painéis à área disponível no monitor correto.
- Em superfícies Wayland, prefira animar o conteúdo interno sem redimensionar a janela nativa a cada frame, conforme o padrão do launcher. Mantenha máscara de entrada e foco coerentes com a área visível.
- Reutilize serviços e integrações existentes. Evite processos frequentes, polling desnecessário, efeitos gráficos caros e trabalho pesado em bindings.
- Novos textos de interface devem passar por `I18n.qml`, com entradas para `pt_BR` e `en_US`. Não confunda texto exibido com identificadores internos ou nomes fornecidos por aplicativos.
- Ao adicionar singletons, atualize `singletons/qmldir`. Não edite caminhos gerados em `/nix/store` nem altere dependências ou `flake.lock` sem relação com a tarefa.

## Documentação pública

- `README.md` é a versão principal em português brasileiro e `README.en.md` é sua contraparte em inglês. Preserve links de alternância de idioma no topo e mantenha estrutura, comandos, avisos e recursos equivalentes nas duas versões.
- Não traduza nomes de propriedades, caminhos, comandos, endpoints IPC ou identificadores de código. Traduza apenas a explicação ao redor deles.
- Imagens versionadas ficam em `docs/assets/`, usam nomes descritivos e precisam de texto alternativo nas duas línguas. Comprima ativos grandes quando isso não prejudicar a legibilidade.
- Diferencie explicitamente arte conceitual de captura real da interface. Screenshots não devem expor notificações, nomes, caminhos ou outras informações pessoais.
- Ao mudar instalação, dependências, configuração, IPC, arquitetura ou limitações conhecidas, atualize os dois READMEs na mesma alteração.
- Prefira exemplos copiáveis e verificados. Não anuncie suporte, compatibilidade ou verificações que o código atual não oferece.

## Desenvolvimento e validação

O flake fornece um pacote executável e um ambiente de desenvolvimento, mas ainda não há uma suíte de testes automatizada.

```sh
nix develop
quickshell -n -p .
```

Execute a shell em uma sessão gráfica compatível. Antes de abrir uma segunda instância, confira se já existe uma instância ativa: barras, notificações e atalhos podem entrar em conflito. Não encerre processos do usuário sem autorização.

- Para mudanças exclusivamente documentais, revise clareza, paridade entre os dois READMEs, caminhos de imagens e `git diff --check`; não é necessário iniciar a interface.
- Para mudanças QML, use `qmllint` nos arquivos alterados quando disponível no ambiente. Diferencie erros reais de limitações conhecidas dos imports de Quickshell; não suprima avisos amplamente para obter uma saída limpa.
- Valide mudanças visuais na sessão real quando possível: alinhamento, contraste, hover, foco, teclado, abertura/fechamento, textos longos e limites da tela. Confira múltiplos monitores e escala quando a alteração afetar geometria.
- Verifique logs para erros QML, bindings quebrados e acessos a propriedades inexistentes. Para alterações em Nix, execute verificações compatíveis com os outputs declarados.
- Use testes proporcionais à mudança. Não crie infraestrutura de testes para ajustes cosméticos simples.
- Revise o diff final e execute `git diff --check`. Informe o que mudou, o que foi validado e qualquer validação que não pôde ser feita; não declare sucesso de verificações não executadas.

## Critérios de conclusão

Uma alteração está pronta quando atende ao pedido, mantém coerência com MD3 + Apple, reutiliza tokens e componentes adequados, preserva as interações existentes e passa pelas verificações pertinentes. Não amplie o trabalho para uma reformulação global sem solicitação.
