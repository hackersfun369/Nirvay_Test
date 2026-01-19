import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/playlist_provider.dart';
import '../../models/music_track.dart';

class AddToPlaylistDialog extends StatelessWidget {
  final MusicTrack track;

  const AddToPlaylistDialog({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);

    return AlertDialog(
      title: const Text('Add to Playlist'),
      content: SizedBox(
        width: double.maxFinite,
                child: playlistProvider.playlists.isEmpty
                    ? _buildCreatePlaylistOption(context, playlistProvider)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCreatePlaylistOption(context, playlistProvider),
                          const Divider(),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: playlistProvider.playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlistProvider.playlists[index];
                                return ListTile(
                                  leading: const Icon(Icons.playlist_add),
                                  title: Text(playlist.name),
                                  onTap: () async {
                                    try {
                                      await playlistProvider.addToPlaylist(playlist, track);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Added to ${playlist.name}')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to add: $e')),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }

  Widget _buildCreatePlaylistOption(BuildContext context, PlaylistProvider provider) {
    return ListTile(
      leading: const Icon(Icons.add, color: Colors.green),
      title: const Text('Create New Playlist', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      onTap: () {
        // Show dialog to enter name
        showDialog(
          context: context, 
          builder: (context) {
             final controller = TextEditingController();
             return AlertDialog(
               title: const Text('New Playlist'),
               content: TextField(
                 controller: controller,
                 decoration: const InputDecoration(hintText: 'Playlist Name'),
                 autofocus: true,
               ),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                 TextButton(
                   onPressed: () async {
                      if (controller.text.isNotEmpty) {
                        try {
                           // Pass the track to be added immediately
                           await provider.createPlaylist(controller.text, initialTrack: track);
                           
                           if (context.mounted) {
                             Navigator.pop(context); // Close name dialog
                             Navigator.pop(context); // Close list dialog
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Created "${controller.text}" and added song')),
                             );
                           }
                        } catch (e) {
                           print("Error creating playlist: $e");
                        }
                      }
                   }, 
                   child: const Text('Create'),
                 ),
               ],
             );
          }
        );
      },
    );
  }
}
