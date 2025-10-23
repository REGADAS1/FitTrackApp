# NVRTAP – Aplicação de Gestão de Treinos e Alunos

> 📌 Projeto desenvolvido por **Gonçalo Regadas** (🇵🇹 Portugal) como parte de um trabalho pessoal e de portfólio, com foco em criar uma solução funcional para gestão de treinos entre Personal Trainers e alunos.  
> ⚠️ Este repositório contém apenas o **código-fonte** e não distribui versões compiladas.

A **NVRTAP** é uma aplicação multiplataforma desenvolvida em **Flutter** (Android & Web), projetada para **Personal Trainers (PT)** e **alunos** que desejam gerir treinos, acompanhar progresso e manter comunicação num só ambiente.  
O objetivo é oferecer uma ferramenta intuitiva e completa que una **planeamento**, **monitorização** e **motivação**.

---

## 🎯 Funcionalidades

### 👤 Para o Aluno
- ✅ **Autenticação** com Firebase (login/registo)
- ✅ **Seleção de objetivo**: perder peso, ganhar massa muscular, etc.
- ✅ **Foto de perfil** (galeria ou câmara)
- ✅ **Dashboard personalizada (nova)**:
  - Saudação com nome e foto
  - **Agenda de Treinos** integrada: cartões “**Treino de hoje**” e “**Próximo treino**” puxados do calendário do PT
  - **Gráfico de Periodização** com fases (ex.: Força/ Hipertrofia) por cores e **marcador diário**
  - **KPIs**: treinos da semana, minutos totais, fase de periodização atual (com intervalo), **streak**
  - **Ações rápidas**: botão “**Iniciar treino**” com cronómetro integrado
  - **Metas do dia** (checklists configuráveis)
  - **Hidratação** (contador 0–8 copos)
- ✅ **Perfil de utilizador**:
  - Edição de nome, altura, peso e foto
  - Logout seguro
- ✅ **Plano de treino atribuído**:
  - Organização por grupos musculares
  - Acesso a vídeos/imagens dos exercícios
- ✅ **Cronómetro de treino** com animações e registo automático de duração
- ✅ **Feed**:
  - “Frase do dia” (definida pelo PT)
  - Posts com texto e imagem (upload para Cloudinary)
  - Marcação/Tag de alunos

---

### 🏋️‍♀️ Para o Personal Trainer (Web)
- ✅ **Gestão de alunos**:
  - Lista com nome, altura, peso e objetivo
  - **Painel lateral deslizante** com detalhes rápidos e ações
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
- ✅ **Calendário interativo**:
  - Base **Syncfusion Calendar**
  - **Pinch-to-Zoom** (zoom por gesto) em vista semanal/diária
  - Agendamento de treinos para cada aluno
  - **Integração direta com a dashboard do aluno**
- ✅ **Periodização por aluno (novo)**:
  - Página **PeriodizationPage** para criar/editar/eliminar **fases** (título, notas, cor, início/fim)
  - Cores selecionáveis (paleta)
  - Sincronização com o **gráfico de Periodização** na dashboard do aluno
- ✅ **Avaliações**:
  - Página dedicada a **PTAssessments** (medidas/observações)

---

## 🛠️ Tecnologias Utilizadas

- **Flutter** (Mobile & Web)
- **Firebase Authentication** – gestão de utilizadores
- **Firebase Cloud Firestore** – base de dados em tempo real
- **Cloudinary** – armazenamento de imagens e vídeos
- **fl_chart** – gráficos de progresso
- **syncfusion_flutter_calendar** – calendário com pinch-to-zoom
- **intl** – formatação de datas
- **image_picker** – seleção de imagens
- **Provider** – gestão de estado

---

## ✨ Novidades Principais

- **Dashboard redesenhada**
- **Treino de hoje / Próximo treino** diretamente do calendário do PT
- **Gráfico de Periodização** com fases coloridas e marcador diário
- **KPI de Periodização** com nome e datas
- **Página PeriodizationPage** para gestão de fases (com cores, progresso e estado)
- **Calendário com zoom e eventos personalizados**
- **Feed com Frase do Dia e posts multimédia**

---

## 🔧 Configuração & Execução

### 1. Pré-requisitos
- Flutter SDK instalado  
- Projeto Firebase configurado (Android/Web)  
- Conta Cloudinary configurada  

### 2. Instalação
```bash
git clone <url-do-repo>
cd nvrtap
flutter pub get
```

### 3. Firebase
- Criar app Android/Web  
- Adicionar `google-services.json` (Android)  
- Ativar **Authentication** e **Cloud Firestore**

### 4. Cloudinary
- Adicionar credenciais no serviço `CloudinaryService`

### 5. Executar
```bash
flutter run -d chrome     # Web
flutter run -d android    # Android
```

---

## 📂 Estrutura do Projeto

```
lib/
├── data/
│   ├── core/               # Tema e assets
│   ├── models/             # Modelos
│   ├── repository/         # Repositórios
│   └── sources/            # Serviços externos (Cloudinary)
├── domain/
│   ├── entities/           # Entidades de negócio
│   ├── repository/         # Interfaces
│   └── usecases/           # Casos de uso
├── presentation/
│   ├── auth/pages/         # Autenticação e onboarding
│   ├── menus/              # Páginas do aluno
│   │   ├── dashboard_page.dart
│   │   ├── calendar_page.dart
│   │   ├── cronometer.dart
│   │   ├── chat_page.dart
│   │   ├── user_profile_page.dart
│   │   └── feed_page.dart
│   ├── widgets/            # Componentes reutilizáveis
│   │   └── sidebar.dart
│   └── PT/                 # Interface Web do PT
│       ├── pt_dashboard.dart
│       ├── exercise_list.dart
│       ├── assign_workout.dart
│       ├── view_workouts.dart
│       ├── pt_assessments_page.dart
│       └── periodization_page.dart
└── main.dart
```

---

## 🧱 Estrutura de Dados (Firestore)

```
users/{userId}
  ├── firstName, lastName, email, goal, ...
  ├── weights/{date}
  ├── workout_logs/{id}
  ├── daily_goals/{yyyy-MM-dd}
  ├── hydration/{yyyy-MM-dd}
  └── periodization_phases/{id}

availability/{id}
  ├── userId
  ├── start, end (Timestamp)
  └── title, color

posts/{id}
  ├── authorId
  ├── text, imageUrl, tags[]
  └── createdAt

feedPhrase/singleton
  └── text
```

---

## 🧑‍💻 Autor & Contacto

**Gonçalo Regadas**  
📩 regadas02@gmail.com  
👔 [linkedin.com/in/regadas02](https://linkedin.com/in/regadas02)

---

## 📜 Licença

Distribuído sob a licença **MIT** apenas para fins de estudo e portfólio.  
Não é permitida a redistribuição ou utilização comercial sem autorização prévia do autor.
