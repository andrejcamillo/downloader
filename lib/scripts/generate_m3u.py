import os
import sys

def generate_m3u_playlist(directory_path, playlist_filename, file_list_path):
    """
    Gera um arquivo de playlist M3U contendo apenas os arquivos especificados
    em um arquivo de lista.

    Args:
        directory_path (str): O diretório onde os arquivos de áudio estão localizados.
        playlist_filename (str): O nome do arquivo M3U a ser criado (ex: "minhaplaylist.m3u").
        file_list_path (str): O caminho para um arquivo de texto contendo a lista
                               de caminhos completos dos arquivos a serem incluídos.
    """
    try:
        with open(file_list_path, 'r', encoding='utf-8') as f:
            audio_files = [line.strip() for line in f if line.strip()]

        if not audio_files:
            print(f"INFO: Nenhum arquivo encontrado na lista '{file_list_path}'. Nenhuma playlist M3U será gerada.")
            return

        os.makedirs(directory_path, exist_ok=True)
        m3u_path = os.path.join(directory_path, playlist_filename)

        with open(m3u_path, 'w', encoding='utf-8') as f:
            f.write("#EXTM3U\n")
            for full_path in audio_files:
                f.write(f"{full_path}\n")

        print(f"INFO: Playlist M3U gerada com sucesso: {m3u_path}")

    except FileNotFoundError:
        print(f"ERRO: O arquivo de lista '{file_list_path}' não foi encontrado.")
    except Exception as e:
        print(f"ERRO: Ocorreu um erro ao gerar a playlist M3U: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python generate_m3u.py <diretorio_destino> <nome_da_playlist.m3u> <caminho_arquivo_lista_de_arquivos>")
        sys.exit(1)

    target_directory = sys.argv[1]
    playlist_name = sys.argv[2]
    list_file_path = sys.argv[3]

    generate_m3u_playlist(target_directory, playlist_name, list_file_path)
