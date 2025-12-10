# Projeto Completo

Problema: Desenvolver um sistema que faça a estimativa de ração necessária para um tanque.
Solução: Criar uma estrutura inteligente que faça a medição de ração disponivel, quanto é consumido por dia e fazer uma previsão de quantos dias irá durar. Realizar a estruturação mínima para desenvolver, treinar, registrar e servir um modelo de estimativa.

Principais componentes:
- coleta (Raspberry Pi)
- ETL / preparação (Airflow DAG)
- treino (Scikit-Learn + TensorFlow)
- registro (MLflow)
- inferência (FastAPI -> Lambda container)
- monitoramento (Evidently)
- visualização (Streamlit)

* Veja o Makefile para comandos rápidos.*

Como Utilizar:

Existem duas instâncias diferentes do programa. Uma inclui LTSM Tensor Flow + evidently para aplicações complexas e outra somente o Scikit-Learn. Para rodar com ou sem Tensor Flow, basta ir na pasta de scripts onde estará separado em duas pastas diferentes e executar a versão desejada. A ordem dos Scripts está em ordem. Alternativamente, você pode utilizar o Makefile dentro das pastas. Atenção, o Makefile que está na raiz da pasta é para uma instalação somente das dependências essênciais.
Observação: Apesar de existir uma opção para rodar o código inteiro de uma única vez na versão sem TF, é recomendado rodar cada instância do script por vez.

Projeções futuras:
* Remover a versão que usa somente o Scikit-Learn
* Criar interação mobile com android
* Adicionar funções relativas a qualidade da água e verificação de doenças comuns presentes em tanques
* Criar um banco de dados virtual composto dos tipos de peixes para uma previsão de tamanho de tanque, quantidade de peixes e quantidade de ração a ser consumida com base em seus comprimentos médios.