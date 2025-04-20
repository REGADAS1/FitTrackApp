# 💪 NVRTAP – Aplicação de Gestão de Treinos e Alunos

A **NVRTAP** é uma aplicação desenvolvida em **Flutter** (Mobile & Web), pensada para Personal Trainers (PT) e os seus alunos. A app permite gerir alunos, atribuir planos de treino personalizados, acompanhar progresso e manter a motivação ao longo da jornada de fitness.

## 🚀 Tecnologias Utilizadas

- **Flutter** (Mobile e Web)
- **Firebase Firestore** (Base de dados em tempo real)
- **Firebase Authentication** (Gestão de contas de utilizadores)
- **Cloudinary** (Armazenamento de imagens e vídeos)
- **Provider** (Gestão de estado)
- **Flutter Web** (Dashboard do PT)

## 👤 Funcionalidades para o Utilizador (Aluno)

- **Autenticação** com Firebase (Login e registo)
- **Seleção de Objetivo**: perder peso, ganhar massa muscular, etc.
- **Upload de Foto de Perfil** (galeria ou câmara)
- **Dashboard personalizada** com:
  - Saudação com nome e foto
  - Evolução do peso em gráfico (progresso diário)
- **Perfil de Utilizador**:
  - Visualização e edição de dados pessoais (nome, altura, peso, foto)
  - Logout seguro
- **Plano de Treino Atribuído**:
  - Visualização do plano organizado por grupos musculares
  - Acesso aos vídeos dos exercícios

## 🏋️‍♀️ Funcionalidades da Personal Trainer (PT)

A versão **Flutter Web** oferece uma **dashboard administrativa** para a PT:

- **Gestão de Alunos**:
  - Visualização dos dados dos utilizadores: nome, altura, peso, objetivo
  - Subpágina deslizante com detalhes do aluno
- **Gestão de Exercícios**:
  - Adicionar exercícios com:
    - Nome
    - Grupo muscular
    - Upload de **imagem ou vídeo** para Cloudinary
  - Filtragem de exercícios por grupo muscular
- **Atribuição de Planos de Treino**:
  - Criação de plano com:
    - Nome personalizado
    - Seleção de grupos musculares envolvidos
    - Drag & drop dos exercícios disponíveis
  - Associação do plano a um aluno
- **Visualização de Planos de Treino**:
  - Lista de planos organizados por grupo muscular
  - Acesso rápido ao conteúdo dos treinos

## 📋 Funcionalidades a Implementar

- 📲 **Notificações Push** para lembretes de treino
- 📝 **Feedback e progresso**: campo para notas ou comentários da PT
- 📅 **Agenda de treinos semanais** (calendário interativo)
- 📃 **Chat** (para comunicação direta entre alunos e PT) 
- 🧠 **Recomendações baseadas em progresso** (AI futura)
- 📈 **Análises avançadas**: gráficos de performance e consistência
- 🌐 **Multi-idioma** (português / inglês)
- 🔐 **Gestão de permissões** para múltiplos treinadores

## 📁 Estrutura do Projeto (exemplo)

