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

- `shell.qml`: inicia notificações, launcher e barras por monitor.
- `AppBar.qml`: compõe bandeja, botão de volume, relógio e OSD por monitor.
- `singletons/Theme.qml`: tokens compartilhados de cor, fonte, medidas e movimento. `textPrimary` e `textSecondary` representam os papéis de texto sobre superfícies.
- `singletons/Config.qml`: resolução do monitor ativo, com fallback.
- `singletons/I18n.qml`: traduções `pt_BR` e `en_US`; altere `locale` para selecionar o idioma.
- `widgets/Notification.qml`: servidor, expiração e lista de notificações.
- `widgets/NotificationCard.qml`: apresentação, ações e resposta de cada notificação.
- `widgets/ApplicationLauncher.qml`: pesquisa e execução de aplicativos.
- `widgets/Volume.qml`: OSD de volume e mute.
- Demais arquivos em `widgets/`: controles e composição visual reutilizável.
- `icons/`: SVGs locais.

O botão de controles mostra o volume; o painel aberto pelo relógio ainda é uma estrutura inicial, sem widgets de conteúdo. Não há persistência de histórico em disco.

## Launcher

```sh
quickshell ipc -p . call launcher toggle
quickshell ipc -p . call launcher close
quickshell ipc -p . call launcher isOpen
```

Use as setas para selecionar resultados, Enter para abrir e Escape para fechar. Configure o atalho desejado no compositor usando o comando `toggle`.

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
qmlformat -i shell.qml AppBar.qml singletons/*.qml widgets/*.qml
```

Confira visualmente foco, teclado, estados de interação, notificações, diferentes resoluções e múltiplos monitores. Consulte `AGENTS.md` antes de alterar o projeto. `.qmlls.ini` contém caminhos locais gerados pela sessão e não deve ser usado como configuração portátil de build.
