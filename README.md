# AnimeAPI

AnimeAPI is a Flutter app for browsing anime, viewing title details, and keeping a temporary saved list and viewing history.

## App Flow

1. The app opens on the login screen. Enter any non-empty name to start a guest session; the optional password is not validated or sent to a server.
2. The dashboard greets the entered name and loads the top anime list. Pull down on the Home tab to refresh it.
3. Use the dashboard navigation to switch between Home, Browse, My List, History, and Profile.
4. Select an anime to open its details. The detail view shows available metadata and synopsis, and its bookmark button adds or removes the title from My List.
5. Opening a title adds it to History, with the most recently opened title first. The Profile tab shows the guest name and provides logout.

Saved titles and viewing history are kept in dashboard memory only. They are not persisted and are cleared when the dashboard session ends.

## Data Sources

- Top anime: Jikan REST API v4 (`/top/anime`, limited to 25 results). If that request fails, the app displays a small built-in fallback list.
- Browse search: searches Jikan REST API v4 for up to 10 results. Search input is debounced; HTTP 429/5xx responses and timeouts are retried, with AniList GraphQL used if Jikan does not return a successful response.
- Anime images are loaded from the image URLs supplied by the APIs.

No API key or account is required. Network access is needed for live anime data and images; top anime has fallback entries when its request fails.

## Run Locally

Requires the Flutter SDK and a configured target device, emulator, or desktop platform.

```sh
flutter pub get
flutter run
```

Run the widget tests with:

```sh
flutter test
```

## Project Structure

- `lib/main.dart`: app setup, themes, and initial route.
- `lib/screens/`: login, dashboard, browse, collection, and detail screens.
- `lib/models/anime.dart`: anime model and Jikan/AniList JSON mapping.
- `lib/services/api_service.dart`: remote API requests, retry/fallback handling, and top-anime fallback data.
- `test/widget_test.dart`: widget tests for login, dashboard navigation, and browse search.
