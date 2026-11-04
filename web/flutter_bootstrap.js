{{flutter_js}}
{{flutter_build_config}}

// Uygulamayı #app kutusunun içinde başlat. Bu kutu iPhone'un çentiği ve
// alttaki ana ekran çizgisi şeridi dışında kalacak şekilde konumlanır
// (index.html'deki CSS). Böylece alt menüye dokunuşlar iOS'a takılmaz.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: document.getElementById('app'),
    });
    await appRunner.runApp();
  },
});
