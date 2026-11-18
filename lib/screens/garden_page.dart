import 'package:material_ui/material_ui.dart';

import '../services/garden_service.dart';

const gardenGreen = Color(0xFF287A49);
const gardenLight = Color(0xFFE5F4E8);
const gardenBackground = Color(0xFFFFFCF7);
const gardenInk = Color(0xFF17241B);

class GardenPage extends StatefulWidget {
  const GardenPage({super.key});

  @override
  State<GardenPage> createState() => _GardenPageState();
}

class _GardenPageState extends State<GardenPage> {
  String selectedFilter = 'all';
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> posts = [];
  Map<String, dynamic> overview = {};

  final filters = const {
    'all': 'All plants',
    'vegetables': 'Vegetables',
    'herbs': 'Herbs',
    'flowers': 'Flowers',
    'mine': 'My posts',
  };

  @override
  void initState() {
    super.initState();
    loadGarden();
  }

  Future<void> loadGarden() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        GardenService.getPosts(selectedFilter),
        GardenService.getOverview(),
      ]);

      if (!mounted) return;

      setState(() {
        posts = results[0] as List<Map<String, dynamic>>;
        overview = results[1] as Map<String, dynamic>;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> changeFilter(String filter) async {
    setState(() {
      selectedFilter = filter;
      loading = true;
      error = null;
    });

    try {
      final result = await GardenService.getPosts(filter);

      if (!mounted) return;

      setState(() {
        posts = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: gardenInk,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ],
    );
  }

  Widget card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gardenInk, width: 1.5),
      ),
      child: child,
    );
  }

  Widget composer() {
    return card(
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: gardenLight,
                child: Icon(Icons.person_outline, color: gardenGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showComingSoon('Create post'),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    "Share what's growing...",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => showComingSoon('Photo upload'),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Photo'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => showComingSoon('Tag plant'),
                icon: const Icon(Icons.local_offer_outlined),
                label: const Text('Tag plant'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget filterBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.entries.map((entry) {
          final selected = selectedFilter == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => changeFilter(entry.key),
              selectedColor: gardenLight,
              backgroundColor: Colors.white,
              side: const BorderSide(color: gardenInk, width: 1.2),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget postCard(Map<String, dynamic> post) {
    final author = post['author_name']?.toString() ?? 'Gardener';
    final username = post['username']?.toString() ?? '';
    final age = post['age']?.toString() ?? '';
    final caption = post['caption']?.toString() ?? '';
    final photo = post['photo_url']?.toString() ?? '';
    final plant = post['plant_name']?.toString() ?? '';
    final likes = post['like_count'] ?? 0;
    final comments = post['comment_count'] ?? 0;
    final liked = post['is_liked'] == true;

    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: gardenLight,
                child: Icon(Icons.person, color: gardenGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '@$username · $age',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => showComingSoon('Post options'),
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(caption, style: const TextStyle(fontSize: 14, height: 1.5)),
          if (plant.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: gardenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plant,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (photo.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  photo,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 40),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: () => showComingSoon('Likes'),
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? Colors.red : gardenInk,
                  size: 20,
                ),
                label: Text('$likes'),
              ),
              TextButton.icon(
                onPressed: () => showComingSoon('Comments'),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: gardenInk,
                  size: 20,
                ),
                label: Text('$comments'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget plantOfTheWeek() {
    final plant = overview['plant_of_the_week'];

    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Plant of the week'),
          const SizedBox(height: 14),
          if (plant == null)
            const Text('No plants yet.')
          else ...[
            if ((plant['photo_url'] ?? '').toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    plant['photo_url'].toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) =>
                        const Center(child: Icon(Icons.local_florist)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              plant['name']?.toString() ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              plant['scientific_name']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plant['short_line']?.toString() ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showComingSoon('Growing guide'),
              child: const Text('VIEW GROWING GUIDE'),
            ),
          ],
        ],
      ),
    );
  }

  Widget upcomingEvents() {
    final events = (overview['upcoming_events'] as List<dynamic>?) ?? [];

    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Upcoming events'),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text('No upcoming events yet.')
          else
            ...events.map((event) {
              final name = event['name']?.toString() ?? '';
              final location = event['location']?.toString() ?? '';
              final date = event['start_time']?.toString() ?? '';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: gardenLight,
                  child: Icon(Icons.event, color: gardenGreen),
                ),
                title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '$location\n${date.length >= 10 ? date.substring(0, 10) : date}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => showComingSoon('Event details'),
              );
            }),
        ],
      ),
    );
  }

  Widget gardenTip() {
    final tip = overview['garden_tip']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gardenLight,
        border: Border.all(color: gardenInk, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_outlined, color: gardenGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's garden tip",
                  style: TextStyle(
                    color: gardenGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(tip, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gardenBackground,
      appBar: AppBar(
        title: const Text(
          'Grow Your Garden',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: gardenLight,
        foregroundColor: gardenInk,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: gardenLight),
                child: Text(
                  'Grow Your Garden',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.spa_outlined),
                title: const Text('Garden'),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadGarden,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const Text(
              'Garden',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: gardenInk,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "See what's growing in your neighborhood",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            composer(),
            const SizedBox(height: 28),
            sectionTitle(
              'Community garden',
              subtitle: 'Latest from the community',
            ),
            const SizedBox(height: 12),
            filterBar(),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              card(
                child: Column(
                  children: [
                    const Text('Could not load garden data.'),
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    TextButton(
                      onPressed: loadGarden,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (posts.isEmpty)
              card(
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.spa_outlined, size: 40, color: gardenGreen),
                        SizedBox(height: 12),
                        Text('No posts here yet'),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: postCard(post),
                ),
              ),
            const SizedBox(height: 12),
            plantOfTheWeek(),
            const SizedBox(height: 18),
            upcomingEvents(),
            const SizedBox(height: 18),
            gardenTip(),
          ],
        ),
      ),
    );
  }
}
