# Orla

Shell de desktop em QML/Quickshell para Wayland/Hyprland, com linguagem visual baseada em Material Design 3 e acabamento inspirado na Apple.

## Executar

Em uma sessão gráfica Wayland com Hyprland:

```sh
nix run .
```

Para trabalhar diretamente nos arquivos do repositório:

```sh
nix develop
quickshell -n -p .
```

O pacote instala o comando `orla` e inclui os arquivos QML, o Quickshell, as dependências Qt e a fonte Sunghyun Sans em seu closure. O ambiente de desenvolvimento fornece as mesmas dependências para executar e verificar os arquivos locais. PipeWire fornece os dados de áudio. Não há suíte de testes automatizados.

## Instalar no NixOS

Adicione o repositório aos inputs da flake da configuração do sistema:

```nix
inputs.orla = {
  url = "github:SEU_USUARIO/orla";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Depois, receba o input em `outputs` e adicione o pacote à configuração:

```nix
outputs = inputs@{ nixpkgs, orla, ... }: {
  nixosConfigurations.seu-host = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ({ pkgs, ... }: {
        environment.systemPackages = [
          orla.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      })
    ];
  };
};
```

O comando `orla` fica disponível no sistema. Para iniciá-lo junto com o Hyprland, use `exec-once = orla` na configuração do compositor. Troque a URL do exemplo pelo endereço do repositório. Durante o desenvolvimento, ela também pode apontar para `path:/caminho/para/orla`.

## Organização

- `shell.qml`: compõe as superfícies globais e as instâncias por monitor.
- `surfaces/`: janelas Wayland da barra superior e das notificações.
- `components/`: primitivas visuais reutilizáveis, sem responsabilidade de domínio.
- `singletons/Theme.qml`: tokens compartilhados de cor, fonte, medidas e movimento. `textPrimary` e `textSecondary` representam os papéis de texto sobre superfícies.
- `singletons/Config.qml`: resolução do monitor ativo, com fallback.
- `singletons/I18n.qml`: traduções `pt_BR` e `en_US`; altere `locale` para selecionar o idioma.
- `services/`: lógica sem interface para busca/ativação do launcher e expiração de notificações.
- `singletons/NotificationStore.qml`: servidor de notificações e histórico compartilhado da sessão.
- `surfaces/NotificationOverlay.qml`: superfície e lista das notificações ativas.
- `widgets/NotificationHistory.qml`: histórico da sessão agrupado por aplicativo dentro da ilha.
- `widgets/NotificationCard.qml`: apresentação, ações e resposta de cada notificação.
- `surfaces/TopBar.qml`: superfície superior criada por monitor; reserva a área da barra e reúne a ilha expansível, o system tray e o OSD de volume.
- `widgets/VolumeOsd.qml`: OSD de volume e mute.
- Demais arquivos em `widgets/`: controles e composição visual reutilizável.
- `icons/`: SVGs locais.

Um clique no relógio expande a própria ilha para mostrar os controles do sistema. O launcher continua acessível pelo atalho configurado no compositor. O histórico de notificações não é persistido em disco.

## Launcher

```sh
quickshell ipc -p . call launcher toggle
quickshell ipc -p . call launcher close
quickshell ipc -p . call launcher isOpen
quickshell ipc -p . call wallpapers toggle
quickshell ipc -p . call wallpapers close
quickshell ipc -p . call wallpapers isOpen
```

Use as setas para selecionar resultados, Enter para abrir e Escape para fechar. Configure o atalho desejado no compositor usando o comando `toggle`.

Ao abrir sem texto, o launcher mostra em uma linha até seis aplicativos mais usados, ordenados pela contagem de aberturas e pela utilização mais recente em caso de empate. A contagem é persistida em `$XDG_STATE_HOME/orla-launcher.json` (ou `~/.local/state/orla-launcher.json`) e continua disponível após reiniciar ou atualizar a shell. A pesquisa combina aplicativos instalados, arquivos não ocultos do diretório pessoal e até 500 páginas recentes do perfil `~/.config/BraveSoftware/Brave-Origin/Default/History`. O banco do Brave é aberto somente para leitura; arquivos e páginas são abertos pelo aplicativo padrão do sistema.

O seletor de wallpapers lista as imagens de `~/.config/hypr/wallpapers`, permite filtrar pelo nome e aplica a escolha em todos os monitores pelo `hyprpaper`. Para abri-lo pelo Hyprland, associe `Alt+W` a `orla ipc call wallpapers toggle`.

## Verificação

Dentro de `nix develop`, execute:

```sh
bash scripts/check-qml.sh
```

O script usa os imports do ambiente e verifica todos os arquivos QML. O analisador pode emitir avisos de metadados do Quickshell sobre `PanelWindow`, `margins` e enums de âncoras; confira também os logs da instância ativa:

```sh
quickshell log -p . -t 50 --no-color
```

Para formatar:

```sh
qmlformat -i shell.qml components/*.qml services/*.qml singletons/*.qml surfaces/*.qml widgets/*.qml
```

Confira visualmente foco, teclado, estados de interação, notificações, diferentes resoluções e múltiplos monitores. Consulte `AGENTS.md` antes de alterar o projeto. `.qmlls.ini` contém caminhos locais gerados pela sessão e não deve ser usado como configuração portátil de build.
