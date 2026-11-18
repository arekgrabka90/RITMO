# RITMO

### Planejador pessoal de trabalho e controle de fechamento de turnos

**RITMO** é um planejador pessoal para profissionais de hotelaria e gastronomia. Reúne a organização da escala, o registro de turnos e seus fechamentos em um único aplicativo Android.

**Status do projeto:** 0.0.1 em desenvolvimento  
**Plataforma:** celulares e tablets Android  
**Modelo:** aplicativo pessoal, local e offline

**Outros idiomas:** [English](README.md) · [Polski](README.pl.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

---

## Visão do projeto

O trabalho em hotelaria e gastronomia envolve escalas variáveis, diferentes locais e funções, horas trabalhadas, gorjetas, dinheiro em espécie e pagamentos com cartão. O RITMO pretende oferecer um único espaço prático para registrar e organizar essas informações.

O RITMO foi concebido como uma ferramenta pessoal para profissionais individuais do setor. Não é um sistema de gestão de restaurantes, uma plataforma de gestão de funcionários ou um produto SaaS.

## Princípios fundamentais

- **Pessoal:** inicialmente destinado a uma única pessoa.
- **Offline:** as funções principais e os dados são armazenados localmente no dispositivo.
- **Privado:** sem contas, backend, serviços em nuvem ou sincronização no escopo inicial.
- **Flexível:** os recursos são adicionados gradualmente.
- **Confiável:** integridade dos dados, migrações de banco testadas e backup/restauração são requisitos importantes.
- **Adaptável:** um único aplicativo para celulares e tablets Android.
- **Registros separados:** o salário pago pelo empregador e os fechamentos de turno são áreas independentes.

## Versão 0.0.1

A primeira versão concentra-se na estrutura do aplicativo e no fluxo essencial de gestão do trabalho.

### Locais de trabalho e funções
- Criar e editar locais de trabalho.
- Definir nome, cor, moeda e observação.
- Criar funções vinculadas a cada local de trabalho.
- Arquivar e restaurar locais de trabalho e funções.

### Turnos e escala
- Criar, editar e excluir turnos.
- Atribuir um local de trabalho e, opcionalmente, uma função.
- Informar manualmente os horários de início e término.
- Marcar turnos como planejados ou trabalhados.
- Adicionar observações.
- Consultar turnos por dia e navegar entre meses.

Punch in/out, pausas, arredondamento de tempo e cálculo automático de salário não fazem parte da versão 0.0.1.

### Fechamentos de turno

Cada fechamento está associado a um turno específico. A versão 0.0.1 está planejada para permitir um fechamento por turno e as seguintes categorias:

1. Gorjetas em dinheiro — total das gorjetas em espécie.
2. Gorjetas no cartão — total das gorjetas pagas no cartão.
3. Imposto sobre gorjetas no cartão.
4. Repasse de gorjetas — pagamentos para cozinha e bar.
5. Vendas e pagamentos — dados de vendas e conciliação de pagamentos.
6. Controle de dinheiro — conferência do caixa.

É possível adicionar itens individuais com rótulos, valores e observações opcionais. Itens personalizados também são aceitos.

**Nenhum cálculo de fechamento é realizado.** Nesta versão, o RITMO não soma, subtrai, interpreta ou distribui valores automaticamente, não calcula impostos e não impõe procedimentos de fechamento.

### Configurações e interface
- Temas claro, escuro e do sistema.
- Navegação e layouts adaptáveis para celulares e tablets.
- Armazenamento local de dados e configurações.
- Seções planejadas: Hoje, Escala, Fechamentos, Finanças e Mais.

Algumas seções serão intencionalmente limitadas na primeira versão.

### Backup e restauração
A versão 0.0.1 inclui backup e restauração manual do banco de dados:
- Exportar uma cópia do banco para um arquivo escolhido pelo usuário.
- Validar o backup antes da restauração.
- Verificar a integridade do banco e a compatibilidade do esquema antes de substituir os dados atuais.

O backup em nuvem do sistema Android está desativado por decisão do projeto. Os arquivos de backup devem ser guardados em local seguro. A desinstalação do aplicativo pode remover o banco de dados local.

## Privacidade e propriedade dos dados

A versão inicial foi projetada para funcionar sem conta online ou backend remoto. Cada dispositivo mantém seu próprio banco de dados local. A sincronização entre dispositivos não está incluída.

O projeto não prevê transmitir registros pessoais de trabalho ou fechamentos para servidores externos.

## Tecnologia

A stack Android planejada inclui:
- Kotlin
- Jetpack Compose
- Material 3
- Room / SQLite
- DataStore
- Navigation Compose

As versões finais das bibliotecas e os detalhes de implementação serão definidos durante o desenvolvimento.

## Integridade dos dados e tratamento de horário

A implementação deve seguir estes princípios:
- Migrações explícitas do banco, testadas com bancos que contenham dados existentes.
- Nenhum mecanismo de migração destrutiva como alternativa.
- Integridade referencial e restrições adequadas no banco.
- Valores monetários armazenados como números inteiros nas menores unidades da moeda.
- Registros de data e hora armazenados em UTC junto com o identificador do fuso horário de origem.
- Tratamento correto de turnos que atravessam a meia-noite e das mudanças de horário de verão, incluindo horários locais inexistentes ou repetidos.
- Validação dos backups antes da restauração ou substituição do banco ativo.

## Roteiro de desenvolvimento

| Versão | Direção planejada |
|---|---|
| 0.0.1 | Estrutura do aplicativo, locais de trabalho, funções, turnos, fechamentos básicos e backup/restauração manual |
| 0.0.2 | Punch in/out e outros recursos de controle de tempo |
| Versões futuras | Gestão de salários, ferramentas financeiras ampliadas e recursos adicionais de fechamento |

Os recursos futuros serão especificados e aprovados separadamente.

## Fora do escopo da versão 0.0.1

- Contas e suporte a vários usuários.
- Backend, serviços em nuvem e sincronização.
- Integrações com POS e sistemas de restaurantes.
- Cálculo automático de impostos ou distribuição de gorjetas.
- Motor de regras e cálculos automáticos de fechamento.
- Cálculo de salários.
- Análises financeiras avançadas e previsões.
- Punch in/out, pausas e arredondamento de tempo.
- Geofencing, Wear OS e widgets.
- Notificações avançadas.
- Exportação avançada para PDF ou planilhas.
- Compartilhamento de registros com outras pessoas.

## Documentação do repositório

As especificações e decisões de desenvolvimento são mantidas em documentos separados:

- `RITMO_0.0.1_SCOPE.md` — escopo da primeira versão.
- `RITMO_0.0.1_ROADMAP.md` — etapas de implementação.
- `RITMO_0.0.1_DATA_MODEL.md` — modelo de dados proposto.
- `RITMO_0.0.1_ACCEPTANCE.md` — critérios de aceitação e testes.
- `RITMO_DECISIONS.md` — decisões aprovadas, propostas e questões em aberto.

## Status do desenvolvimento

O RITMO 0.0.1 está em desenvolvimento. Este README descreve os objetivos e o escopo planejado do projeto; não afirma que todos os recursos listados já estejam implementados ou verificados.

Antes de considerar a versão concluída, é necessário verificar a compilação, os testes automatizados, as migrações do banco, o backup/restauração e o funcionamento em celulares e tablets.

---

**RITMO — Organize seu trabalho. Mantenha o controle dos seus dados.**
