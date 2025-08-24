abstract class FavoritesStates {}

class FavoritesInitialState extends FavoritesStates {}

class FavoritesUpdatingState extends FavoritesStates {}

class FavoritesUpdatedState extends FavoritesStates {}

class FavoritesLoadingState extends FavoritesStates {}

class FavoritesSuccessState extends FavoritesStates {}

class FavoritesErrorState extends FavoritesStates {
  final String error;

  FavoritesErrorState(this.error);
}
