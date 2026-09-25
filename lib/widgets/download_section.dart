// lib/widgets/download_section.dart

import 'package:flutter/material.dart';

class DownloadSection extends StatefulWidget {
  final Function(String link, bool fromYouTube, bool mp3Format, String outputDir) onDownload;
  final bool isDownloading;

  const DownloadSection({
    super.key,
    required this.onDownload,
    required this.isDownloading,
  });

  @override
  State<DownloadSection> createState() => _DownloadSectionState();
}

class _DownloadSectionState extends State<DownloadSection> {
  final _linkController = TextEditingController();
  bool _fromYouTube = true;
  bool _mp3Format = true;
  final String _outputDir = '';
  // ⚡ Estado para o Switch de playlist
  bool _generateM3uPlaylist = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  // Você pode ter um método para salvar a preferência em algum lugar, como SharedPreferences
  void _saveM3uSetting() {
    // Implemente a lógica para salvar a preferência
    // Exemplo: SharedPreferences.getInstance().then((prefs) => prefs.setBool('generateM3u', _generateM3uPlaylist));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🔹 ToggleButtons para seleção de Fonte (YouTube/Spotify)
        ToggleButtons(
          isSelected: [_fromYouTube, !_fromYouTube],
          onPressed: (index) {
            setState(() {
              _fromYouTube = index == 0;
            });
          },
          borderRadius: BorderRadius.circular(10),
          fillColor: Colors.blue,
          selectedColor: Colors.white,
          color: Colors.white,
          borderColor: Colors.blue,
          selectedBorderColor: Colors.blue,
          borderWidth: 1,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('YouTube'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Spotify'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔹 ToggleButtons para seleção de Formato (MP3/MP4)
        ToggleButtons(
          isSelected: [_mp3Format, !_mp3Format],
          onPressed: (index) {
            setState(() {
              _mp3Format = index == 0;
            });
          },
          borderRadius: BorderRadius.circular(10),
          fillColor: Colors.blue,
          selectedColor: Colors.white,
          color: Colors.white,
          borderColor: Colors.blue,
          selectedBorderColor: Colors.blue,
          borderWidth: 1,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('MP3'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('MP4'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔹 Switch para Gerar Playlist, visível apenas se MP3 estiver selecionado
        if (_mp3Format)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Gerar playlist .m3u', style: TextStyle(color: Colors.white)),
              Switch(
                value: _generateM3uPlaylist,
                onChanged: (bool value) {
                  setState(() {
                    _generateM3uPlaylist = value;
                    _saveM3uSetting(); // Salva a preferência
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),

        const SizedBox(height: 20),

        // 🔹 Campo de Texto para o Link
        TextField(
          controller: _linkController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Cole o link aqui',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Tooltip(
                message: 'Insira um link de musica/video ou playlist',
                child: Icon(Icons.info, color: Colors.black54),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 🔹 Botão de Download
        ElevatedButton.icon(
          onPressed: widget.isDownloading
              ? null
              : () {
            widget.onDownload(
              _linkController.text,
              _fromYouTube,
              _mp3Format,
              _outputDir,
            );
          },
          icon: widget.isDownloading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Icon(Icons.download),
          label: const Text('Baixar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 🔹 Tooltip de aviso legal
        Tooltip(
          message:
          'Antes de baixar uma música, é fundamental verificar a origem da música e os direitos autorais associados para garantir a legalidade do download e evitar problemas. '
              'Consulte sites de plataformas legais de música, bibliotecas de músicas livres de direitos autorais ou entre em contato direto com os criadores ou detentores dos direitos para obter permissão, se necessário. '
              'O desenvolvedor se isenta da responsabilidade pelos downloads efetuados pelo usuário, uma vez que é aceite o termo de baixar única e exclusivamente músicas que não firam os termos citados acima.',
          padding: const EdgeInsets.all(12.0),
          preferBelow: false,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          child: const Icon(
            Icons.info_outline,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}