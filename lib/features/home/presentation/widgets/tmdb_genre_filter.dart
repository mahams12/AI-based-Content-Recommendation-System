import 'package:flutter/material.dart';

class TMDBGenreFilter extends StatefulWidget {
  final List<String> selectedGenres;
  final Function(List<String>) onGenresChanged;

  const TMDBGenreFilter({
    super.key,
    required this.selectedGenres,
    required this.onGenresChanged,
  });

  @override
  State<TMDBGenreFilter> createState() => _TMDBGenreFilterState();
}

class _TMDBGenreFilterState extends State<TMDBGenreFilter> {
  static const Map<int, String> _tmdbGenres = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Science Fiction',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tmdbGenres.length,
        itemBuilder: (context, index) {
          final genreId = _tmdbGenres.keys.elementAt(index);
          final genreName = _tmdbGenres[genreId]!;
          final isSelected = widget.selectedGenres.contains(genreId.toString());
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                genreName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    widget.onGenresChanged([...widget.selectedGenres, genreId.toString()]);
                  } else {
                    widget.onGenresChanged(
                      widget.selectedGenres.where((g) => g != genreId.toString()).toList()
                    );
                  }
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: Colors.purple,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? Colors.purple : Colors.grey[600]!,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}



