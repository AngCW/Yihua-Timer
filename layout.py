import codecs

with codecs.open('d:/debate 2025/Yihua-Timer/lib/FlowManager/page_manager_page.dart', 'r', 'utf-8') as f:
    text = f.read()

old1 = '''                                              // Section Name
                                              _buildDraggableItem(
                                                x: _sectionX,'''
new1 = '''                                              // Section Name
                                              _buildDraggableItem(
                                                alignment: _selectedPageType == 'B' ? Alignment.center : Alignment.topCenter,
                                                x: _sectionX,'''
text = text.replace(old1, new1)

old2 = '''                                              // Timer A1
                                              if (_selectedPageType == 'A1')
                                                _buildDraggableItem(
                                                  x: _t1X,'''
new2 = '''                                              // Timer A1
                                              if (_selectedPageType == 'A1')
                                                _buildDraggableItem(
                                                  alignment: Alignment.center,
                                                  x: _t1X,'''
text = text.replace(old2, new2)

old3 = '''                                              // Timer A2
                                              if (_selectedPageType == 'A2') ...[
                                                _buildDraggableItem(
                                                  x: _tL_X,'''
new3 = '''                                              // Timer A2
                                              if (_selectedPageType == 'A2') ...[
                                                _buildDraggableItem(
                                                  alignment: const Alignment(-0.5, 0.0),
                                                  x: _tL_X,'''
text = text.replace(old3, new3)

old4 = '''                                                ),
                                                _buildDraggableItem(
                                                  x: _tR_X,'''
new4 = '''                                                ),
                                                _buildDraggableItem(
                                                  alignment: const Alignment(0.5, 0.0),
                                                  x: _tR_X,'''
text = text.replace(old4, new4)

old5 = '''  Widget _buildDraggableItem({
    required double x,
    required double y,
    required double scale,
    required Function(double, double, double) onChanged,
    required Widget child,
  }) {
    return Positioned(
      left: 100 + x,
      top: 100 + y,
      child: GestureDetector('''
new5 = '''  Widget _buildDraggableItem({
    Alignment alignment = Alignment.center,
    required double x,
    required double y,
    required double scale,
    required Function(double, double, double) onChanged,
    required Widget child,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(x, y),
        child: GestureDetector('''
text = text.replace(old5, new5)

with codecs.open('d:/debate 2025/Yihua-Timer/lib/FlowManager/page_manager_page.dart', 'w', 'utf-8') as f:
    f.write(text)
