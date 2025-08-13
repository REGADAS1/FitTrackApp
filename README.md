# 💪 NVRTAP – Aplicação de Gestão de Treinos e Alunos

> 📌 Projeto desenvolvido por **Gonçalo Regadas** (🇵🇹 Portugal) como parte de um trabalho pessoal e de portfólio, com foco em criar uma solução funcional para gestão de treinos entre Personal Trainers e alunos.  
> ⚠️ Este repositório contém apenas o **código-fonte** e não distribui versões compiladas.

---

A **NVRTAP** é uma aplicação multiplataforma desenvolvida em **Flutter** (Android & Web), projetada para **Personal Trainers (PT)** e **alunos** que desejam gerir treinos, acompanhar progresso e manter comunicação num só ambiente.  
O objetivo é oferecer uma ferramenta intuitiva e completa que una **planeamento**, **monitorização** e **motivação**.

---

## 🎯 Funcionalidades

### 👤 Para o Aluno
- ✅ **Autenticação** com Firebase (login/registo)
- ✅ **Seleção de objetivo**: perder peso, ganhar massa muscular, etc.
- ✅ **Foto de perfil** (galeria ou câmara)
- ✅ **Dashboard personalizada**:
  - Saudação com nome e foto
  - Gráfico de evolução do peso (progresso diário)
- ✅ **Perfil de utilizador**:
  - Edição de nome, altura, peso e foto
  - Logout seguro
- ✅ **Plano de treino atribuído**:
  - Organização por grupos musculares
  - Acesso a vídeos/imagens dos exercícios
- ✅ **Cronómetro de treino** com animações e registo de tempo gasto

---

### 🏋️‍♀️ Para o Personal Trainer (via Web)
- ✅ **Gestão de alunos**:
  - Lista com nome, altura, peso e objetivo
  - Subpágina deslizante com detalhes completos
- ✅ **Gestão de exercícios**:
  - Adicionar nome, grupo muscular e imagem/vídeo
  - Upload para **Cloudinary**
  - Filtragem por grupo muscular
- ✅ **Criação de planos de treino**:
  - Nome personalizado
  - Seleção de grupos musculares (checklist)
  - Drag & drop para adicionar exercícios
  - Associação a alunos
- ✅ **Visualização de planos**:
  - Lista por grupos musculares
  - Acesso rápido ao conteúdo
- ✅ **Calendário interativo** (estilo Google Calendar) para agendamento de treinos
- ✅ **Chat integrado** com alunos (mensagens privadas e grupos)

---

## 🛠️ Tecnologias Utilizadas

- **Flutter** (Mobile & Web)
- **Firebase Authentication** – Gestão de utilizadores
- **Firebase Firestore** – Base de dados em tempo real
- **Cloudinary** – Armazenamento de imagens e vídeos
- **fl_chart** – Gráficos de progresso
- **Provider** – Gestão de estado

---

## 📋 Funcionalidades Futuras
- 📲 Notificações push para lembretes
- 🧠 Recomendações de treino com IA
- 📈 Análises avançadas de performance
- 🌐 Multi-idioma (PT/EN)
- ⌚ Integração com wearables
- 🔐 Gestão multi-treinador

---

## 📂 Estrutura do Projeto

lib/
├── data/
│ ├── common/ # Helpers e widgets reutilizáveis
│ ├── core/ # Configurações de tema e assets
│ ├── models/ # Modelos de dados
│ ├── repository/ # Implementações de repositórios
│ └── sources/ # Serviços externos (ex: Cloudinary)
├── domain/
│ ├── entities/ # Entidades de negócio
│ ├── repository/ # Interfaces de repositórios
│ └── usecases/ # Casos de uso
├── presentation/
│ ├── auth/pages/ # Ecrãs de autenticação e onboarding
│ ├── menus/ # Páginas principais (aluno)
│ ├── splash/ # Ecrãs iniciais
│ ├── widgets/ # Componentes reutilizáveis
│ └── PT/ # Interface da Personal Trainer (Web)
├── utils/ # Funções utilitárias
└── main.dart # Ponto de entrada da aplicação

---

## 🧑‍💻 Autor & Contacto

**Gonçalo Regadas**   
📩 [regadas02@gmail.com]
👔 [linkedin.com/in/regadas02/]

---

## 📜 Licença

Este projeto é distribuído sob a licença MIT apenas para fins de estudo e portfólio.  
Não é permitida a redistribuição ou utilização comercial sem autorização prévia do autor.
