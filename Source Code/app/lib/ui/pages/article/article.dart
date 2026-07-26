import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/models/article.dart';
import 'package:woofcare/services/articles.dart';
import 'package:woofcare/ui/widgets/app_chrome.dart';
import 'package:woofcare/ui/widgets/article_card.dart';
import 'package:woofcare/ui/widgets/responsive.dart';

/// ArticlePage - Main screen that displays all articles from Firebase.
/// Features: Search, category filtering, and real-time updates from database.

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  // Tracks which category is currently selected (All, Guide, Medical, Stories)
  String selectedCategory = 'All';

  // Controls the search input field
  final TextEditingController searchController = TextEditingController();

  // Service that handles all Firebase database operations
  final Articles _articleService = Articles();

  // Stores search results. null = show all articles, list = show filtered results
  List<Article>? searchResults;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Performs search when user types in the search bar.
  /// Empty query shows all articles, otherwise filters by title match.
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = null;
      });
      return;
    }
    final results = await _articleService.searchArticles(query);
    setState(() {
      searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WoofCareColors.primaryBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                WoofCareScreenHeader(
                  title: 'Articles',
                  subtitle: 'Care guides and rescue stories',
                  icon: Icons.menu_book_rounded,
                  height: 192,
                  searchController: searchController,
                  searchHint: 'Search articles',
                  onSearchChanged: _performSearch,
                  actions: [
                    WoofCareProfileAvatar(
                      onTap: () => Navigator.pushNamed(context, "/profile"),
                    ),
                  ],
                  bottom: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _buildCategoryButton('All'),
                        const SizedBox(width: 8),
                        _buildCategoryButton('Guide'),
                        const SizedBox(width: 8),
                        _buildCategoryButton('Medical'),
                        const SizedBox(width: 8),
                        _buildCategoryButton('Stories'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: WoofCareContentSurface(
                    maxWidth: 1120,
                    child: searchResults != null
                        ? _buildSearchResults()
                        : _buildArticlesList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single category filter button (All, Guide, Medical, Stories).
  /// Highlights the button if it's currently selected.
  Widget _buildCategoryButton(String category) {
    final isSelected = selectedCategory == category;
    return WoofCareFilterPill(
      label: category,
      selected: isSelected,
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
    );
  }

  /// Builds the main article list using real-time data from Firebase.
  /// Automatically updates when articles are added/removed from database.
  Widget _buildArticlesList() {
    return StreamBuilder<List<Article>>(
      stream: _articleService.getArticlesByCategory(selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: WoofCareColors.buttonColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading articles',
              style: TextStyle(color: WoofCareColors.primaryTextAndIcons),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const WoofCareEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No articles found',
            message: 'New care resources will appear here when available.',
          );
        }

        return _buildArticleCollection(snapshot.data!);
      },
    );
  }

  /// Displays filtered search results when user searches for articles.
  Widget _buildSearchResults() {
    if (searchResults!.isEmpty) {
      return const WoofCareEmptyState(
        icon: Icons.search_off,
        title: 'No articles found',
        message: 'Try a different care topic or category.',
      );
    }

    return _buildArticleCollection(searchResults!);
  }

  Widget _buildArticleCollection(List<Article> articles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 820;
        final horizontalPadding = useGrid ? 24.0 : 11.0;

        if (useGrid) {
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              124,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              mainAxisExtent: 193,
            ),
            itemCount: articles.length,
            itemBuilder: (context, index) => _buildArticleCard(articles[index]),
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            124,
          ),
          itemCount: articles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildArticleCard(articles[index]),
        );
      },
    );
  }

  Widget _buildArticleCard(Article article) {
    return ArticleCard(
      category: article.category,
      title: article.title,
      author: article.author,
      date: DateFormat('MMM yyyy').format(article.date),
      imageUrl: article.imageUrl,
      onTap: () => _openArticle(article),
    );
  }

  Future<void> _openArticle(Article article) async {
    if (article.sourceUrl == null || article.sourceUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This article has no source URL'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final uri = Uri.parse(article.sourceUrl!);
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open article: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
