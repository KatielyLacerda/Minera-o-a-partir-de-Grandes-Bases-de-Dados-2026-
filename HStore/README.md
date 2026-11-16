# Destaques acadêmicos com HStore

Neste projeto, usamos a base sintética Alunos80K para acrescentar destaques acadêmicos à tabela `Configura`. Criamos a coluna `Destaques`, do tipo `hstore`, e preenchemos suas chaves com informações de notas e frequência dos alunos.

| Chave | Critério | Valor armazenado |
|---|---|---|
| Distinção | Alguma nota final maior ou igual a 9 | Maior nota final entre as aprovações |
| Trancamento | Frequência zero e nota final até 0,5 na mesma matrícula | Códigos das disciplinas |
| Bom | Pelo menos duas disciplinas distintas com nota final maior ou igual a 8 | Quantidade dessas disciplinas |

Relacionamos `Matricula` e `Turma` para identificar a disciplina de cada matrícula. Usamos `UPDATE` para os alunos que já estão em `Configura` e `INSERT` para os demais, incluindo também o nome. Preservamos a coluna `Config` e acumulamos as chaves de `Destaques` com `COALESCE` e `||`.

## Arquivos

- `base/Alunos80K/`: scripts e CSVs para gerar a base, adaptados para o Mac.
- `referencia/S1.2-ExploraDS-Alunos80K-Mac.ipynb`: carga e exploração da base.
- `referencia/7.1-PrepDados-HStore.ipynb`: preparação da tabela `Configura`.
- `sql/01_origem.sql`: view temporária com as notas, frequência e disciplinas.
- `sql/02_resolucao.sql`: criação de `Destaques` e aplicação das três regras.
- `sql/03_conferir.sql`: consultas para conferir os resultados.
- `executar.sql`: executa a resolução em uma transação e mostra os resultados.
- `apresentacao/Resolucao_HStore_Alunos80K.pptx`: slides da resolução.

## Como rodar

Precisamos do PostgreSQL em execução, do cliente `psql` e de um ambiente Jupyter com `ipython-sql`, `SQLAlchemy`, `psycopg2-binary` e `ipywidgets`. O usuário do banco precisa ter permissão para criar a base, ativar a extensão `hstore` e alterar as tabelas.

### 1. Gerar a base

Abrimos `referencia/S1.2-ExploraDS-Alunos80K-Mac.ipynb`, configuramos nossa senha nas células de carga e conexão e executamos a carga antes das consultas.

A carga cria o banco `alunos80k`. Se ele já existir, o script interrompe sem apagá-lo. Não precisamos repetir essa etapa se a base já estiver carregada.

Os caminhos foram preparados para esta pasta no Mac:

```text
/Users/katielylacerda/Downloads/HStore
```

Se movermos o projeto, ajustamos o caminho do `Tudo.sql` no notebook, a variável `ScriptPath` em `Tudo.sql` e os caminhos dos CSVs nos scripts de carga. O cliente configurado no notebook é `/opt/homebrew/bin/psql`; alteramos esse caminho se a instalação for diferente.

### 2. Preparar a tabela Configura

Abrimos `referencia/7.1-PrepDados-HStore.ipynb`, configuramos a conexão com `alunos80k` e executamos as células em ordem.

Mantemos a tabela `Configura`: não executamos a célula `DROP TABLE IF EXISTS Configura;`, caso ela esteja presente no final. A preparação gera 40 mil registros com configurações aleatórias.

### 3. Executar o exercício

No terminal, dentro da pasta do projeto, executamos:

```bash
psql -h localhost -p 5432 -U postgres -d alunos80k -f executar.sql
```

Informamos a senha quando solicitada. Ajustamos host, porta e usuário se nossa conexão for diferente.

O arquivo principal cria a view temporária, aplica as três regras entre `BEGIN` e `COMMIT` e exibe as consultas de conferência. Executamos os scripts na mesma conexão porque a view é temporária. Se ocorrer um erro antes do `COMMIT`, a transação não é salva.

Se a listagem ocupar várias páginas, pressionamos **Espaço** para avançar ou **q** para sair. A mensagem `INSERT 0 0` indica que o passo não inseriu novos registros; ele ainda pode ter atualizado alunos existentes.

### 4. Conferir os resultados

Podemos executar novamente apenas a conferência:

```bash
psql -h localhost -p 5432 -U postgres -d alunos80k -f sql/03_conferir.sql
```

Na execução conferida neste projeto, obtivemos:

| Resultado | Quantidade |
|---|---:|
| Registros em Configura | 40.156 |
| Com Distinção | 1 |
| Com Trancamento | 300 |
| Com Bom | 0 |

As categorias podem se sobrepor. Como a base e as configurações são sintéticas, novas gerações podem produzir outros resultados.

## Reexecução

Podemos repetir a resolução com a mesma origem sem inserir alunos duplicados. Não repetimos o notebook de preparação depois do exercício, pois ele recria `Configura` e remove os destaques calculados.

Se alterarmos as notas posteriormente, a resolução acrescenta ou atualiza as chaves dos alunos elegíveis, mas não remove automaticamente chaves de quem deixou de atender aos critérios.

## Material de referência

Usamos o enunciado fornecido pelo professor e os notebooks de geração da base e preparação de HStore. O slide chama o notebook de preparação de `6.1`; o arquivo disponível neste projeto é o `7.1`.
