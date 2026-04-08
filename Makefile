clean: 
	@echo "Cleaning the project..."
	@flutter clean

get:
	@echo "project pub get..."
	@flutter pub get

runner:
	@echo "project build running..."
	@flutter pub run build_runner build --delete-conflicting-outputs

apk:
	@echo "build running..."
	@flutter clean
	@flutter pub get
	@flutter build apk

ios:
	@echo "build running..."
	@flutter clean
	@flutter pub get
	@flutter build ios

aab:
	@echo "build running..."
	@flutter clean
	@flutter pub get
	@flutter build appbundle