// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::process::{Command, Stdio};
use std::collections::HashMap;

// Comando que verifica o status de uma lista de pacotes
#[tauri::command]
fn verify_flatpak_installation(packages: Vec<String>) -> HashMap<String, bool> {
    let mut status_map = HashMap::new();

    for package_name in packages {
        // Executa `flatpak info <pacote>` para verificar o status.
        let status = Command::new("flatpak")
            .arg("info")
            .arg(&package_name)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();

        match status {
            Ok(exit_status) => {
                // `exit_status.success()` retorna true se o código de saída for 0.
                status_map.insert(package_name, exit_status.success());
            }
            Err(_) => {
                // Se o comando flatpak falhar (ex: não encontrado), assume que o pacote não está instalado.
                status_map.insert(package_name, false);
            }
        }
    }

    status_map
}

#[tauri::command]
fn check_installed_packages(packages: Vec<String>) -> HashMap<String, bool> {
    let mut status_map = HashMap::new();

    for package_name in packages {
        // Executa `dpkg -s <pacote>` para verificar o status.
        // Redirecionamos a saída para /dev/null porque só nos importa o código de saída.
        let status = Command::new("dpkg")
            .arg("-s")
            .arg(&package_name)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();

        match status {
            Ok(exit_status) => {
                // `exit_status.success()` retorna true se o código de saída for 0.
                status_map.insert(package_name, exit_status.success());
            }
            Err(_) => {
                // Se o comando dpkg falhar (ex: não encontrado), assume que o pacote não está instalado.
                status_map.insert(package_name, false);
            }
        }
    }

    status_map
}

#[tauri::command]
fn check_snap_packages(packages: Vec<String>) -> HashMap<String, bool> {
    let mut status_map = HashMap::new();

    // Primeiro, inicializa todos os pacotes solicitados como 'não instalados' (false).
    // Isso garante que cada pacote na requisição receba uma resposta.
    for package_name in &packages {
        status_map.insert(package_name.clone(), false);
    }

    // Executa `snap list` uma única vez para obter todos os pacotes instalados.
    let output = match Command::new("snap").arg("list").output() {
        Ok(output) => output,
        Err(_) => {
            // Se o comando `snap` falhar (ex: snapd não está instalado),
            // retorna o mapa com todos os pacotes como 'false'.
            return status_map;
        }
    };

    // Se o comando não foi executado com sucesso, não há snaps para verificar.
    if !output.status.success() {
        return status_map;
    }

    let stdout = String::from_utf8_lossy(&output.stdout);

    // Itera sobre as linhas da saída do `snap list`, pulando a primeira linha (cabeçalho).
    for line in stdout.lines().skip(1) {
        // O nome do pacote é sempre a primeira palavra da linha.
        if let Some(installed_package_name) = line.split_whitespace().next() {
            // Se o pacote instalado estiver na nossa lista de interesse, atualiza seu status para 'true'.
            if status_map.contains_key(installed_package_name) {
                status_map.insert(installed_package_name.to_string(), true);
            }
        }
    }

    status_map
}


fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            // Adicione sua nova função aqui, junto com outras que você possa ter
            check_installed_packages,
            verify_flatpak_installation,
            check_snap_packages
            // greet, // Exemplo de outra função que você possa ter
        ])
        .run(tauri::generate_context!())
        .expect("erro ao iniciar a aplicação");
}
