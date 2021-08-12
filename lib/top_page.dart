

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildElevatedButton(String text, Function()? func) {
    return ElevatedButton(
      child: Text(text),
      style: ElevatedButton.styleFrom(
        primary: Colors.orange,
        onPrimary: Colors.white,
      ),
      onPressed: func,
    );
  }

  String createRoomId() {
    return const Uuid().v4();
  }

  void newRoom() {
    print(createRoomId());
  }

  void newPeer() {
    wrapper.newPeer('05bd41ee-71ec-4d8b-bd68-f6b7e1172b76', 3,
        allowInterop((peerId) => print(peerId)));
  }

  Widget _buildNewGamePage() {
    return Center(
        child: Column(children: [
          _buildElevatedButton("New Peer", newPeer),
          _buildElevatedButton("New Room", newRoom),
          _buildElevatedButton("Join Room", null),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    print(size);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body:
        _buildNewGamePage() //Image.asset("images/manzu_all/p_ms1_0.gif") // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
