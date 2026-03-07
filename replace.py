import re, codecs
with codecs.open('d:/debate 2025/Yihua-Timer/lib/FlowManager/page_manager_page.dart', 'r', 'utf-8') as f:
    text = f.read()

# Block 1
old1 = '''                                              // Section Name
                                              _replaceMeDraggable(
                                                alignment:
                                                    _selectedPageType == 'B'
                                                        ? Alignment.center
                                                        : Alignment.topCenter,
                                                child: Text('''
new1 = '''                                              // Section Name
                                              _buildDraggableItem(
                                                x: _sectionX,
                                                y: _sectionY,
                                                scale: _sectionScale,
                                                onChanged: (dx, dy, s) => setState(() {
                                                  _sectionX = dx;
                                                  _sectionY = dy;
                                                  _sectionScale = s;
                                                }),
                                                child: Text('''
text = text.replace(old1.replace('\n', '\r\n'), new1.replace('\n', '\r\n'))
text = text.replace(old1, new1)

# Block 2
old2 = '''                                              // Timer A1
                                              if (_selectedPageType == 'A1')
                                                _replaceMeDraggable(
                                                  alignment: Alignment.center,
                                                  child:
                                                      _buildPreviewTimerWidget('''
new2 = '''                                              // Timer A1
                                              if (_selectedPageType == 'A1')
                                                _buildDraggableItem(
                                                  x: _t1X,
                                                  y: _t1Y,
                                                  scale: _t1Scale,
                                                  onChanged: (dx, dy, s) => setState(() {
                                                    _t1X = dx;
                                                    _t1Y = dy;
                                                    _t1Scale = s;
                                                  }),
                                                  child:
                                                      _buildPreviewTimerWidget('''
text = text.replace(old2.replace('\n', '\r\n'), new2.replace('\n', '\r\n'))
text = text.replace(old2, new2)

# Block 3
old3 = '''                                              // Timer A2
                                              if (_selectedPageType == 'A2')
                                                _replaceMeDraggable(
                                                  alignment: Alignment.center,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      _buildPreviewTimerWidget(
                                                        time: _previewSecLeft,
                                                        isRunning:
                                                            _isPreviewRunningLeft,
                                                        onToggle:
                                                            _togglePreviewTimerLeft,
                                                        onReset: () {
                                                          _previewTimerLeft
                                                              ?.cancel();
                                                          _updatePreviewSeconds();
                                                          setState(() {
                                                            _isPreviewRunningLeft =
                                                                false;
                                                          });
                                                        },
                                                      ),
                                                      _buildPreviewTimerWidget(
                                                        time: _previewSecRight,
                                                        isRunning:
                                                            _isPreviewRunningRight,
                                                        onToggle:
                                                            _togglePreviewTimerRight,
                                                        onReset: () {
                                                          _previewTimerRight
                                                              ?.cancel();
                                                          _updatePreviewSeconds();
                                                          setState(() {
                                                            _isPreviewRunningRight =
                                                                false;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),'''
new3 = '''                                              // Timer A2
                                              if (_selectedPageType == 'A2') ...[
                                                _buildDraggableItem(
                                                  x: _tL_X,
                                                  y: _tL_Y,
                                                  scale: _tL_Scale,
                                                  onChanged: (dx, dy, s) => setState(() {
                                                    _tL_X = dx;
                                                    _tL_Y = dy;
                                                    _tL_Scale = s;
                                                  }),
                                                  child: _buildPreviewTimerWidget(
                                                    time: _previewSecLeft,
                                                    isRunning: _isPreviewRunningLeft,
                                                    onToggle: _togglePreviewTimerLeft,
                                                    onReset: () {
                                                      _previewTimerLeft?.cancel();
                                                      _updatePreviewSeconds();
                                                      setState(() {
                                                        _isPreviewRunningLeft = false;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                _buildDraggableItem(
                                                  x: _tR_X,
                                                  y: _tR_Y,
                                                  scale: _tR_Scale,
                                                  onChanged: (dx, dy, s) => setState(() {
                                                    _tR_X = dx;
                                                    _tR_Y = dy;
                                                    _tR_Scale = s;
                                                  }),
                                                  child: _buildPreviewTimerWidget(
                                                    time: _previewSecRight,
                                                    isRunning: _isPreviewRunningRight,
                                                    onToggle: _togglePreviewTimerRight,
                                                    onReset: () {
                                                      _previewTimerRight?.cancel();
                                                      _updatePreviewSeconds();
                                                      setState(() {
                                                        _isPreviewRunningRight = false;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],'''
text = text.replace(old3.replace('\n', '\r\n'), new3.replace('\n', '\r\n'))
text = text.replace(old3, new3)

with codecs.open('d:/debate 2025/Yihua-Timer/lib/FlowManager/page_manager_page.dart', 'w', 'utf-8') as f:
    f.write(text)
