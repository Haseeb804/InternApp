import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FilePreviewDialog extends StatefulWidget {
  final String filePath;
  final String fileName;

  const FilePreviewDialog({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  _FilePreviewDialogState createState() => _FilePreviewDialogState();
}

class _FilePreviewDialogState extends State<FilePreviewDialog> {
  bool _isLoading = true;
  String? _fileContent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      setState(() => _isLoading = true);
      final response = await http.get(Uri.parse(widget.filePath));
      
      if (response.statusCode == 200) {
        if (_isImageFile(widget.fileName)) {
          setState(() {
            _fileContent = base64Encode(response.bodyBytes);
            _isLoading = false;
          });
        } else {
          setState(() {
            _fileContent = utf8.decode(response.bodyBytes);
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load file';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  bool _isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    return imageExtensions.any(
      (ext) => fileName.toLowerCase().endsWith(ext),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(widget.fileName),
              leading: IconButton(
                icon: const FaIcon(FontAwesomeIcons.times),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.download),
                  onPressed: () {
                    // TODO: Implement file download
                  },
                ),
              ],
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.exclamationTriangle, size: 48),
            const SizedBox(height: 16),
            Text(_error!),
          ],
        ),
      );
    }

    if (_fileContent == null) {
      return const Center(child: Text('No content available'));
    }

    if (_isImageFile(widget.fileName)) {
      return Image.memory(
        base64Decode(_fileContent!),
        fit: BoxFit.contain,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(_fileContent!),
    );
  }
}
