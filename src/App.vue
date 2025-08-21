<script setup>
import {ref, onMounted, computed} from "vue";
import { invoke } from "@tauri-apps/api/core";
import { Command } from '@tauri-apps/plugin-shell';
import { getCurrentWindow } from "@tauri-apps/api/window";
import { resourceDir, join } from "@tauri-apps/api/path";
import appsData from "/src/featured_apps.json";


// Saída do terminal (stream)
const isRunning = ref(false);
const exitCode = ref(null);
const stdoutText = ref("");
const stderrText = ref("");
const featuredApps = ref([]);
const selectedCategory = ref('Todos');

const externalLinks = ref([
  {
    name: 'GitHub',
    url: 'https://github.com/lucas-r-santos/linux-tool-kit',
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"></path></svg>'
  },
  {
    name: 'Google',
    url: 'https://google.com',
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></polyline><line x1="10" y1="14" x2="21" y2="3"></line></svg>'
  }
]);

async function openExternalLink(url) {
  try {
    open(url);
  } catch (err) {
    console.error(`Falha ao abrir o link externo ${url}:`, err);
    stderrText.value = `Não foi possível abrir o link: ${err}`;
  }
}

const categories = computed(() => {
  // O Set garante que cada categoria apareça apenas uma vez
  const uniqueCategories = new Set(
      featuredApps.value
          .map(app => app.category) // Pega a categoria de cada app
          .filter(Boolean) // Remove categorias nulas ou vazias
  );
  // Retorna um novo array com "Todos" no início, seguido pelas categorias únicas
  return ['Todos', ...uniqueCategories];
});

// Uma propriedade computada que filtra os aplicativos com base na categoria selecionada
const filteredApps = computed(() => {
  // Se "Todos" estiver selecionado, retorna a lista completa
  if (selectedCategory.value === 'Todos') {
    return featuredApps.value;
  }
  // Caso contrário, retorna apenas os apps que pertencem à categoria selecionada
  return featuredApps.value.filter(app => app.category === selectedCategory.value);
});

const topRowApps = computed(() => {
  return filteredApps.value.slice(0, 5);
});

const bottomRowApps = computed(() => {
  return filteredApps.value.slice(5);
});

function loadFeaturedApps() {
  try {
    // Filtra entradas inválidas (como objetos vazios) antes de armazenar
    featuredApps.value = appsData.filter(app => app && app.id);
  } catch (err) {
    console.error("Erro ao carregar a lista de aplicativos:", err);
    stderrText.value += `\n[erro] Não foi possível carregar a lista de apps: ${err?.message ?? String(err)}`;
  }
}

async function executeBashStreaming(scriptName) {
  stdoutText.value = "";
  stderrText.value = "";

  exitCode.value = null;
  isRunning.value = true;

  try {
    const baseDir = await resourceDir();
    const scriptPath = await join(baseDir, 'resources', 'scripts', scriptName);

    // Apenas um log para sabermos o que está sendo executado
    console.log(`Tentando executar: sh "${scriptPath}"`);

    const cmd = Command.create('run-sh', [
      '-c',
      `pkexec sh "${scriptPath}"`
    ]);

    const decoder = new TextDecoder('utf-8');

    cmd.stdout.on('data', (data) => {
      const text = typeof data === 'string' ? data : decoder.decode(data);
      stdoutText.value += text;
    });

    cmd.stderr.on('data', (data) => {
      const text = typeof data === 'string' ? data : decoder.decode(data);
      stderrText.value += text;
    });

    cmd.on('close', (event) => {
      exitCode.value = event.code;
      isRunning.value = false;
    });

    await cmd.spawn();
  } catch (err) {
    isRunning.value = false;
    stderrText.value += `\n[erro] ${err?.message ?? String(err)}`;
  }
}

// Função para atualizar a categoria selecionada
function selectCategory(category) {
  selectedCategory.value = category;
}

// Opcional: maximizar (se desejar manter)
onMounted(async () => {
  try {
    const win = getCurrentWindow();
    await win.maximize();
  } catch {}

  loadFeaturedApps();
  await updatePackageStatuses();
});

// Executa e devolve tudo no final (buffered)
// Mantido apenas como exemplo; a exibição principal usa streaming
// async function executeBashCommand() {
//   let result = await Command.create('exec-sh', [
//     '-c',
//     "echo 'Hello World!'",
//   ]).execute();
//
//   if (result.code === 0) {
//     stdoutText.value = (result.stdout || '').trim();
//     stderrText.value = '';
//   } else {
//     stdoutText.value = '';
//     stderrText.value = (result.stderr || `Falha (code ${result.code})`).trim();
//   }
//   exitCode.value = result.code;
// }

  async function runPackageManager(action, app) {
    // Bloqueia novas ações se uma já estiver em execução
    if (isRunning.value) {
      console.warn("Aguarde a operação atual ser concluída antes de iniciar outra.");
      return;
    }

    if (!['apt', 'flatpak', 'snap'].includes(app.manager)) {
      stderrText.value = `Gerenciador '${app.manager}' ainda não implementado.`;
      return;
    }

    stdoutText.value = "";
    stderrText.value = "";
    exitCode.value = null;
    app.installing = true;
    isRunning.value = true;

    try {
      const baseDir = await resourceDir();

      let scriptName;
      switch (app.manager) {
        case 'apt':
          scriptName = 'manage_apt_package.sh';
          break;
        case 'flatpak':
          scriptName = 'manage_flatpak_package.sh';
          break;
        case 'snap':
          scriptName = 'manage_snap_package.sh';
          break;
      }

      const scriptPath = await join(baseDir, 'resources', 'scripts', scriptName);

      // Usa o alias 'run-package-manager' e passa a ação (install/remove) e o nome do pacote
      const cmd = Command.create('run-package-manager', [scriptPath, action, app.packageName]);

      const decoder = new TextDecoder('utf-8');

      cmd.stdout.on('data', (data) => {
        const text = typeof data === 'string' ? data : decoder.decode(data);
        stdoutText.value += text;
      });

      cmd.stderr.on('data', (data) => {
        const text = typeof data === 'string' ? data : decoder.decode(data);
        stderrText.value += text;
      });

      cmd.on('close', (event) => {
        exitCode.value = event.code;
        isRunning.value = false;
        app.installing = false;
        updatePackageStatuses();
      });

      await cmd.spawn();
    } catch (err) {
      isRunning.value = false;
      app.installing = false;
      stderrText.value += `\n[erro] ${err?.message ?? String(err)}`;
    }
  }

  function removePackage(app) {
    runPackageManager('remove', app);
  }

async function updatePackageStatuses() {
  console.log("Verificando status dos pacotes...");
  try {
    const aptPackages = featuredApps.value
        .filter(app => app.manager === 'apt' && app.packageName)
        .map(app => app.packageName);

    const flatpakPackages = featuredApps.value
        .filter(app => app.manager === 'flatpak' && app.packageName)
        .map(app => app.packageName);

    const snapPackages = featuredApps.value
        .filter(app => app.manager === 'snap' && app.packageName)
        .map(app => app.packageName);


    const aptStatuses = aptPackages.length > 0
        ? await invoke('check_installed_packages', { packages: aptPackages })
        : {};

    const flatpakStatuses = flatpakPackages.length > 0
        ? await invoke('verify_flatpak_installation', { packages: flatpakPackages })
        : {};

    const snapStatuses = snapPackages.length > 0
        ? await invoke('check_snap_packages', { packages: snapPackages })
        : {};

    const allStatuses = { ...aptStatuses, ...flatpakStatuses, ...snapStatuses };

    // Atualiza o estado 'installed' de cada app na lista
    featuredApps.value.forEach((app) => {
      if (app.packageName) {
        // Define como 'true' se o pacote estiver no mapa e seu valor for verdadeiro.
        // Caso contrário, define como 'false'.
        app.installed = !!allStatuses[app.packageName];
      }
    });

    console.log("Status dos pacotes atualizado com sucesso.");

  } catch (err) {
    console.error("Erro ao verificar status dos pacotes:", err);
  }
}
</script>

<template>
  <!-- Root em dark mode -->
  <div class="min-h-screen bg-slate-900 text-slate-100">
    <div class="grid grid-cols-12">
      <!-- Sidebar -->
      <aside class="col-span-12 md:col-span-3 lg:col-span-2 bg-slate-950/80 border-r border-slate-800 min-h-screen p-4 md:p-5">
        <div class="flex items-center gap-2 font-bold mb-6">
          <span class="text-xl">🐧</span>
          <span>Linux Tool Kit</span>
        </div>

        <nav class="space-y-2">
          <button
              v-for="category in categories"
              :key="category"
              class="w-full text-left px-3 py-2 rounded-lg transition"
              :class="selectedCategory === category
              ? 'bg-slate-800/60 border border-slate-700'
              : 'hover:bg-slate-800/60 border border-transparent hover:border-slate-700'"
              @click="selectCategory(category)"
          >
            {{ category }}
          </button>
        </nav>
        <!-- Seção de Links Externos -->
        <div class="mt-8">
          <h3 class="px-3 text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
            Links
          </h3>
          <nav class="space-y-2">
            <a
                v-for="link in externalLinks"
                :key="link.name"
                :href="link.url"
                target="_blank"
                @click.prevent="openExternalLink(link.url)"
                class="w-full flex items-center gap-3 text-left px-3 py-2 rounded-lg transition border border-transparent hover:bg-slate-800/60 hover:border-slate-700"
            >
              <span v-html="link.icon" class="text-slate-400"></span>
              <span>{{ link.name }}</span>
            </a>
          </nav>
        </div>
      </aside>

      <!-- Conteúdo -->
      <main class="col-span-12 md:col-span-9 lg:col-span-10 min-h-screen">
        <!-- Topbar -->
<!--        <header class="flex items-center justify-between px-4 md:px-6 py-4 border-b border-slate-800 bg-slate-900/60 backdrop-blur">-->
<!--          <h1 class="text-lg font-semibold"></h1>-->
<!--&lt;!&ndash;          <div class="flex items-center gap-2">&ndash;&gt;-->
<!--&lt;!&ndash;            <button&ndash;&gt;-->
<!--&lt;!&ndash;              class="px-3 py-2 rounded-lg border border-slate-700 bg-slate-800/60 hover:bg-slate-700/70 transition text-sm"&ndash;&gt;-->
<!--&lt;!&ndash;              @click="stdoutText = ''; stderrText = ''; exitCode = null"&ndash;&gt;-->
<!--&lt;!&ndash;            >&ndash;&gt;-->
<!--&lt;!&ndash;              Limpar Saída&ndash;&gt;-->
<!--&lt;!&ndash;            </button>&ndash;&gt;-->
<!--&lt;!&ndash;          </div>&ndash;&gt;-->
<!--        </header>-->

        <!-- Loja: Apps em destaque -->
        <section class="px-4 md:px-6 pt-4 md:pt-6">
          <div class="flex items-center justify-between mb-3">
            <h2 class="text-base md:text-lg font-semibold">Em destaque</h2>
            <button class="text-sm text-indigo-400 hover:text-indigo-300">Ver tudo</button>
          </div>

          <!-- Carrossel horizontal (scroll) -->
          <div class="relative">
            <div class="flex justify-center gap-4 overflow-x-auto pb-2 snap-x snap-mandatory">
              <div
                v-for="app in topRowApps"
                :key="app.id"
                class="relative min-w-[240px] max-w-[260px] snap-start bg-slate-900/60 border border-slate-800 rounded-xl p-4 shrink-0"
              >
                <!-- Badge de Ícone de Pacote com Tooltip -->
                <div
                  v-if="app.manager"
                  class="absolute top-2 right-2 flex items-center justify-center w-7 h-7 rounded-full text-white"
                  :class="{
                    'bg-sky-500': app.manager === 'flatpak',
                    'bg-red-600': app.manager === 'apt' || app.manager === 'deb',
                    'bg-orange-500': app.manager === 'snap'
                  }"
                  :title="app.manager === 'flatpak' ? 'Flatpak' : (app.manager === 'snap' ? 'Snap' : 'Pacote DEB')"

                >
                  <!-- Ícone Flatpak -->
                  <svg v-if="app.manager === 'flatpak'" class="w-4 h-4" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M21 15.4286H3V17.5714H21V15.4286Z" /><path d="M14.1429 20.7143L9.85714 17.5714H14.1429V20.7143Z" /><path d="M21.9333 7.5L12 13.5222L2.06667 7.5L12 1.47778L21.9333 7.5ZM12 14.9778L3 8.95556V14.3333H21V8.95556L12 14.9778Z" /></svg>
                  <!-- Ícone Snap -->
                  <svg v-else-if="app.manager === 'snap'" class="w-4 h-4" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1.5 13.5v-3H8v3H6.5v-3H4V11h2.5V8H8v3h2.5V8H12v3h2.5V9.5h-1.3l2.8-4.2h1.7l-3.5 5.1v.1h3.8v1.5h-3.8v3h-1.5v-3H12v3h-1.5z"/></svg>
                  <!-- Ícone Debian (para apt e deb) -->
                  <svg v-else class="w-5 h-5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 14.4c-1.39 0-2.73-.42-3.86-1.16l1.03-1.79c.81.47 1.76.75 2.83.75 1.56 0 2.43-.68 2.43-1.62 0-.9-.6-1.36-2.07-1.82-1.75-.54-3.13-1.35-3.13-3.1 0-1.46 1.06-2.62 2.89-2.93V3.5h1.9v1.31c1.19.26 2.04.98 2.04 2.16 0 .86-.53 1.34-1.78 1.68 1.48.4 2.38 1.36 2.38 2.91 0 1.9-1.53 3.32-4.66 3.32z" /></svg>

                </div>

                <div class="flex items-center gap-3 mb-2">
                  <div class="text-2xl">{{ app.icon }}</div>
                  <div class="font-semibold">{{ app.name }}</div>
                </div>
                <p class="text-sm text-slate-400 line-clamp-2 mb-3">
                  {{ app.summary }}
                </p>
                <div class="flex flex-wrap gap-1.5 mb-3">
                  <span
                      v-for="(tag, i) in app.tags"
                      :key="i"
                      class="text-[11px] px-2 py-0.5 rounded-full bg-slate-800/70 border border-slate-700 text-slate-300"
                  >
                    {{ tag }}
                  </span>
                </div>
                <div class="flex items-center gap-2">
                  <!-- Botão para executar tweaks -->
                  <button
                      v-if="app.category === 'Tweaks' && app.script"
                      class="px-3 py-1.5 rounded-lg border border-teal-500 bg-teal-600 hover:bg-teal-500 transition disabled:opacity-60 disabled:cursor-not-allowed text-sm"
                      :disabled="isRunning"
                      @click="executeBashStreaming(app.script)"
                  >
                    <span v-if="isRunning">Aguarde...</span>
                    <span v-else>Executar</span>
                  </button>
                  
                  <!-- Botões de Instalar/Remover para apps normais -->
                  <template v-else>
                    <button
                        v-if="!app.installed"
                        class="px-3 py-1.5 rounded-lg border border-indigo-500 bg-indigo-600 hover:bg-indigo-500 transition disabled:opacity-60 disabled:cursor-not-allowed text-sm"
                        :disabled="isRunning"
                        @click="runPackageManager('install', app)"
                    >
                      <span v-if="app.installing">Instalando…</span>
                      <span v-else>Instalar</span>
                    </button>

                    <button
                        v-else
                        class="px-3 py-1.5 rounded-lg border border-rose-500 bg-rose-600/90 hover:bg-rose-500 transition text-sm disabled:opacity-60 disabled:cursor-not-allowed"
                        :disabled="isRunning"
                        @click="removePackage(app)"
                    >
                      <span v-if="app.installing">Removendo…</span>
                      <span v-else>Remover</span>
                    </button>

                    <span
                        v-if="app.installed && !app.installing"
                        class="text-emerald-400 text-sm"
                    >
                      Instalado
                    </span>
                  </template>

                </div>
              </div>
            </div>
          </div>
        </section>
        <!-- NOVA SEÇÃO: Mais aplicativos (grade) -->
        <section v-if="bottomRowApps.length > 0" class="px-4 md:px-6 pt-4 md:pt-6">
          <div class="flex items-center justify-between mb-3">
            <h2 class="text-base md:text-lg font-semibold">Mais aplicativos</h2>
          </div>

          <!-- Grade de aplicativos responsiva -->
          <div class="flex flex-wrap justify-center gap-4">
            <div
              v-for="app in bottomRowApps"
              :key="app.id"
              class="relative w-full sm:w-[240px] bg-slate-900/60 border border-slate-800 rounded-xl p-4"
            >
              <!-- Badge de Ícone de Pacote com Tooltip -->
              <div
                v-if="app.manager"
                class="absolute top-2 right-2 flex items-center justify-center w-7 h-7 rounded-full text-white"
                :class="{
                  'bg-sky-500': app.manager === 'flatpak',
                  'bg-red-600': app.manager === 'apt' || app.manager === 'deb',
                  'bg-orange-500': app.manager === 'snap'
                }"
                :title="app.manager === 'flatpak' ? 'Flatpak' : (app.manager === 'snap' ? 'Snap' : 'Pacote DEB')"
              >
                <!-- Ícone Flatpak -->
                <svg v-if="app.manager === 'flatpak'" class="w-4 h-4" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M21 15.4286H3V17.5714H21V15.4286Z" /><path d="M14.1429 20.7143L9.85714 17.5714H14.1429V20.7143Z" /><path d="M21.9333 7.5L12 13.5222L2.06667 7.5L12 1.47778L21.9333 7.5ZM12 14.9778L3 8.95556V14.3333H21V8.95556L12 14.9778Z" /></svg>
                <!-- Ícone Snap -->
                <svg v-else-if="app.manager === 'snap'" class="w-4 h-4" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1.5 13.5v-3H8v3H6.5v-3H4V11h2.5V8H8v3h2.5V8H12v3h2.5V9.5h-1.3l2.8-4.2h1.7l-3.5 5.1v.1h3.8v1.5h-3.8v3h-1.5v-3H12v3h-1.5z"/></svg>
                <!-- Ícone Debian (para apt e deb) -->
                <svg v-else class="w-5 h-5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 14.4c-1.39 0-2.73-.42-3.86-1.16l1.03-1.79c.81.47 1.76.75 2.83.75 1.56 0 2.43-.68 2.43-1.62 0-.9-.6-1.36-2.07-1.82-1.75-.54-3.13-1.35-3.13-3.1 0-1.46 1.06-2.62 2.89-2.93V3.5h1.9v1.31c1.19.26 2.04.98 2.04 2.16 0 .86-.53 1.34-1.78 1.68 1.48.4 2.38 1.36 2.38 2.91 0 1.9-1.53 3.32-4.66 3.32z" /></svg>
              </div>

              <div class="flex items-center gap-3 mb-2">
                <div class="text-2xl">{{ app.icon }}</div>
                <div class="font-semibold">{{ app.name }}</div>
              </div>
              <p class="text-sm text-slate-400 line-clamp-2 mb-3">
                {{ app.summary }}
              </p>
              <div class="flex flex-wrap gap-1.5 mb-3">
                  <span
                      v-for="(tag, i) in app.tags"
                      :key="i"
                      class="text-[11px] px-2 py-0.5 rounded-full bg-slate-800/70 border border-slate-700 text-slate-300"
                  >
                    {{ tag }}
                  </span>
              </div>
              <div class="flex items-center gap-2">
                <button
                    v-if="!app.installed"
                    class="px-3 py-1.5 rounded-lg border border-indigo-500 bg-indigo-600 hover:bg-indigo-500 transition disabled:opacity-60 disabled:cursor-not-allowed text-sm"
                    :disabled="isRunning"
                    @click="runPackageManager('install', app)"
                >
                  <span v-if="app.installing">Instalando…</span>
                  <span v-else>Instalar</span>
                </button>

                <button
                    v-else
                    class="px-3 py-1.5 rounded-lg border border-rose-500 bg-rose-600/90 hover:bg-rose-500 transition text-sm disabled:opacity-60 disabled:cursor-not-allowed"
                    :disabled="isRunning"
                    @click="removePackage(app)"
                >
                  <span v-if="app.installing">Removendo…</span>
                  <span v-else>Remover</span>
                </button>
                <span
                    v-if="app.installed && !app.installing"
                    class="text-emerald-400 text-sm"
                >
                    Instalado
                  </span>
              </div>
            </div>
          </div>
        </section>

        <!-- Cards principais -->
        <section class="p-4 md:p-6 grid grid-cols-12 gap-4 md:gap-6">

          <!-- Executar Comando -->
<!--          Mantido para testes-->
<!--          <div class="col-span-12 lg:col-span-6 bg-slate-900/60 border border-slate-800 rounded-xl p-4 md:p-5 shadow-sm">-->
<!--            <h2 class="text-base font-semibold mb-3">Executar Comando</h2>-->
<!--            <div class="flex flex-wrap gap-2">-->
<!--              <button-->
<!--                class="px-3 py-2 rounded-lg border border-slate-700 bg-slate-800/60 hover:bg-slate-700/70 transition"-->
<!--                @click="executeBashCommand"-->
<!--              >-->
<!--                Executar (final)-->
<!--              </button>-->
<!--              <button-->
<!--                class="px-3 py-2 rounded-lg border border-indigo-500 bg-indigo-600 hover:bg-indigo-500 transition disabled:opacity-50"-->
<!--                :disabled="isRunning"-->
<!--                @click="executeBashStreaming('install_docker.sh')"-->
<!--              >-->
<!--                {{ isRunning ? 'Aguarde...' : 'Executar (stream)' }}-->
<!--              </button>-->
<!--            </div>-->
<!--            <p class="text-slate-400 mt-2 text-sm">-->
<!--              Demonstração usando sh -c com um comando permitido pela capability.-->
<!--            </p>-->
<!--            <div v-if="exitCode !== null" class="mt-3">-->
<!--              Status:-->
<!--              <strong :class="exitCode === 0 ? 'text-emerald-400' : 'text-rose-400'">-->
<!--                {{ exitCode === 0 ? 'sucesso' : 'falha' }}-->
<!--              </strong>-->
<!--              <span class="text-slate-400">(code: {{ exitCode }})</span>-->
<!--            </div>-->
<!--          </div>-->

          <!-- Saída do Terminal -->
          <div class="col-span-12 bg-slate-900/60 border border-slate-800 rounded-xl p-4 md:p-5 shadow-sm">
            <h2 class="text-base font-semibold mb-3">Saída do Terminal</h2>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <div>
                <div class="text-sm text-slate-400 mb-1">stdout</div>
                <pre class="h-56 overflow-auto bg-slate-950 text-slate-100 border border-slate-800 rounded-lg p-3 whitespace-pre-wrap">{{ stdoutText }}</pre>
              </div>
              <div>
                <div class="text-sm text-slate-400 mb-1">stderr</div>
                <pre class="h-56 overflow-auto bg-rose-950/60 text-rose-200 border border-rose-900/60 rounded-lg p-3 whitespace-pre-wrap">{{ stderrText }}</pre>
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  </div>
</template>
