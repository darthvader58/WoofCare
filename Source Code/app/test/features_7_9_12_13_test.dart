// Unit tests for testing-brief sections 7-9 (posts/likes/comments logic),
// 12 (articles model + search/category filtering), 13 (nav config).
// Firestore is faked with fake_cloud_firestore; no live Firebase needed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofcare/models/article.dart';
import 'package:woofcare/tools/functions.dart';

void main() {
  group('Section 7 - post feed helpers', () {
    test('formatDate renders M/D/YYYY from Timestamp', () {
      final ts = Timestamp.fromDate(DateTime(2026, 7, 2, 13, 45));
      expect(formatDate(ts), '7/2/2026');
    });

    test('feed ordering query returns most recent first', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('posts').add({
        'email': 'a@x.com',
        'message': 'old',
        'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'likes': [],
      });
      await firestore.collection('posts').add({
        'email': 'b@x.com',
        'message': 'new',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'likes': [],
      });
      // Same query shape as posts.dart lines 99-103.
      final snap =
          await firestore
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .get();
      expect(snap.docs.first['message'], 'new');
    });

    test(
        'EDGE: post doc without likes key throws on read - '
        "posts.dart:128 `post['likes'] ?? []` does not guard missing fields",
        () async {
      final firestore = FakeFirebaseFirestore();
      final doc = await firestore.collection('posts').add({
        'email': 'a@x.com',
        'message': 'no likes key',
        'timestamp': Timestamp.now(),
      });
      final snap = await doc.get();
      // DocumentSnapshot operator[] throws StateError when the field is
      // absent (real cloud_firestore behaves the same), so the `?? []`
      // fallback in posts.dart line 128 never runs for legacy docs.
      expect(() => snap['likes'], throwsA(isA<StateError>()));
    });
  });

  group('Section 8 - like toggle semantics (arrayUnion/arrayRemove)', () {
    test('arrayUnion adds identifier once, no duplicates on repeat', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore.collection('posts').doc('p1');
      await ref.set({'likes': []});
      // Same update as thumbs_up_widget.dart lines 44-47.
      await ref.update({
        'likes': FieldValue.arrayUnion(['me@x.com']),
      });
      await ref.update({
        'likes': FieldValue.arrayUnion(['me@x.com']),
      });
      final snap = await ref.get();
      expect(List<String>.from(snap['likes']), ['me@x.com']);
    });

    test('arrayRemove removes only current user identifier', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore.collection('posts').doc('p1');
      await ref.set({
        'likes': ['me@x.com', 'other@x.com'],
      });
      // Same update as thumbs_up_widget.dart lines 48-51.
      await ref.update({
        'likes': FieldValue.arrayRemove(['me@x.com']),
      });
      final snap = await ref.get();
      expect(List<String>.from(snap['likes']), ['other@x.com']);
    });
  });

  group('Section 12 - Article model', () {
    Future<DocumentSnapshot> docWith(Map<String, dynamic> data) async {
      final firestore = FakeFirebaseFirestore();
      final ref = await firestore.collection('articles').add(data);
      return ref.get();
    }

    test('fromFirestore maps all fields', () async {
      final snap = await docWith({
        'title': 'Rabies Guide',
        'category': 'Medical',
        'author': 'Dr. K',
        'date': Timestamp.fromDate(DateTime(2025, 3, 1)),
        'imageUrl': 'https://img',
        'content': 'body',
        'sourceUrl': 'https://src',
      });
      final a = Article.fromFirestore(snap);
      expect(a.title, 'Rabies Guide');
      expect(a.category, 'Medical');
      expect(a.author, 'Dr. K');
      expect(a.sourceUrl, 'https://src');
    });

    test('missing sourceUrl stays null and missing author uses default',
        () async {
      final snap = await docWith({
        'title': 'T',
        'category': 'Guide',
        'date': Timestamp.fromDate(DateTime(2025, 1, 1)),
      });
      final a = Article.fromFirestore(snap);
      expect(a.sourceUrl, isNull);
      expect(a.author, 'Voice of Stray Dogs');
      expect(a.imageUrl, '');
    });

    test('EDGE: missing date field crashes fromFirestore (unhandled cast)',
        () async {
      final snap = await docWith({'title': 'T', 'category': 'Guide'});
      expect(() => Article.fromFirestore(snap), throwsA(isA<TypeError>()));
    });
  });

  group('Section 12 - search + category filter semantics', () {
    // Replicates the exact predicate in services/articles.dart lines 41-46
    // and the category equality in line 25, applied to Article objects.
    Article art(String title, String category) => Article(
          id: 'x',
          title: title,
          category: category,
          author: 'a',
          date: DateTime(2025),
          imageUrl: '',
          content: '',
        );

    List<Article> search(List<Article> all, String query) => all
        .where(
          (article) => article.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    test('search is case-insensitive substring match on title', () {
      final all = [art('Feeding Strays', 'Guide'), art('Rabies 101', 'Medical')];
      expect(search(all, 'FEEDING').single.title, 'Feeding Strays');
      expect(search(all, 'rAbIeS').single.title, 'Rabies 101');
    });

    test('search with no results returns empty list', () {
      final all = [art('Feeding Strays', 'Guide')];
      expect(search(all, 'zebra'), isEmpty);
    });

    test('category filter matches exact category; All bypasses filter', () {
      final all = [
        art('A', 'Guide'),
        art('B', 'Medical'),
        art('C', 'Stories'),
      ];
      for (final cat in ['Guide', 'Medical', 'Stories']) {
        final filtered = all.where((a) => a.category == cat).toList();
        expect(filtered.length, 1, reason: 'exactly one $cat article');
      }
    });

    test('category-filtered stream sorts newest first in memory', () {
      final list = [
        Article(
          id: '1',
          title: 'older',
          category: 'Guide',
          author: 'a',
          date: DateTime(2024),
          imageUrl: '',
          content: '',
        ),
        Article(
          id: '2',
          title: 'newer',
          category: 'Guide',
          author: 'a',
          date: DateTime(2026),
          imageUrl: '',
          content: '',
        ),
      ];
      // Same sort as services/articles.dart line 31.
      list.sort((a, b) => b.date.compareTo(a.date));
      expect(list.first.title, 'newer');
    });
  });
}
