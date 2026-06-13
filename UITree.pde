interface UIListener {
  void handle(UIEvent e);
}

class UIEvent {
  String type;
  UINode target;
  UINode currentTarget;
  float x;
  float y;
  boolean propagationStopped;

  UIEvent(String type, UINode target, float x, float y) {
    this.type = type;
    this.target = target;
    this.currentTarget = null;
    this.x = x;
    this.y = y;
    this.propagationStopped = false;
  }

  void stopPropagation() {
    this.propagationStopped = true;
  }
}

class UINode {
  float x;
  float y;
  float w;
  float h;
  boolean visible;
  boolean pickable;

  UINode parent;
  ArrayList<UINode> children;

  HashMap<String, ArrayList<UIListener>> bubbleListeners;
  HashMap<String, ArrayList<UIListener>> captureListeners;

  boolean hovered;
  boolean held;

  UINode(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.visible = true;
    this.pickable = true;
    this.parent = null;
    this.children = new ArrayList<UINode>();
    this.bubbleListeners = new HashMap<String, ArrayList<UIListener>>();
    this.captureListeners = new HashMap<String, ArrayList<UIListener>>();
    this.hovered = false;
    this.held = false;
  }

  UINode add(UINode child) {
    child.parent = this;
    this.children.add(child);
    return child;
  }

  void remove(UINode child) {
    child.parent = null;
    this.children.remove(child);
  }

  void on(String type, UIListener listener) {
    addEventListener(type, listener, false);
  }

  void addEventListener(String type, UIListener listener, boolean capture) {
    HashMap<String, ArrayList<UIListener>> map = capture ? this.captureListeners : this.bubbleListeners;
    if (!map.containsKey(type)) map.put(type, new ArrayList<UIListener>());
    map.get(type).add(listener);
  }

  void removeEventListener(String type, UIListener listener, boolean capture) {
    HashMap<String, ArrayList<UIListener>> map = capture ? this.captureListeners : this.bubbleListeners;
    if (map.containsKey(type)) map.get(type).remove(listener);
  }

  float globalX() {
    return (this.parent == null ? 0 : this.parent.globalX()) + this.x;
  }

  float globalY() {
    return (this.parent == null ? 0 : this.parent.globalY()) + this.y;
  }

  boolean contains(float gx, float gy) {
    float ax = globalX();
    float ay = globalY();
    return gx >= ax && gx <= ax + this.w && gy >= ay && gy <= ay + this.h;
  }

  UINode pick(float gx, float gy) {
    if (!this.visible) return null;
    for (int i = this.children.size() - 1; i >= 0; i--) {
      UINode hit = this.children.get(i).pick(gx, gy);
      if (hit != null) return hit;
    }
    if (this.pickable && contains(gx, gy)) return this;
    return null;
  }
}

class UIStage {
  UINode root;
  UINode hovered;
  UINode pressedTarget;

  UIStage(float w, float h) {
    this.root = new UINode(0, 0, w, h);
    this.root.pickable = false;
    this.hovered = null;
    this.pressedTarget = null;
  }

  UINode add(UINode child) {
    return this.root.add(child);
  }

  ArrayList<UINode> chainOf(UINode node) {
    ArrayList<UINode> chain = new ArrayList<UINode>();
    UINode n = node;
    while (n != null) {
      chain.add(0, n);
      n = n.parent;
    }
    return chain;
  }

  void fire(HashMap<String, ArrayList<UIListener>> map, String type, UIEvent e) {
    ArrayList<UIListener> list = map.get(type);
    if (list == null) return;
    for (int i = 0; i < list.size(); i++) {
      list.get(i).handle(e);
      if (e.propagationStopped) return;
    }
  }

  void dispatch(UINode target, String type, float x, float y, boolean bubbles) {
    if (target == null) return;
    UIEvent e = new UIEvent(type, target, x, y);

    if (!bubbles) {
      e.currentTarget = target;
      fire(target.bubbleListeners, type, e);
      return;
    }

    ArrayList<UINode> chain = chainOf(target);
    for (int i = 0; i < chain.size(); i++) {
      UINode n = chain.get(i);
      e.currentTarget = n;
      fire(n.captureListeners, type, e);
      if (e.propagationStopped) return;
    }
    for (int i = chain.size() - 1; i >= 0; i--) {
      UINode n = chain.get(i);
      e.currentTarget = n;
      fire(n.bubbleListeners, type, e);
      if (e.propagationStopped) return;
    }
  }

  void moved(float x, float y) {
    UINode target = this.root.pick(x, y);
    if (target != this.hovered) {
      applyHoverChange(this.hovered, target, x, y);
      this.hovered = target;
    }
    if (target != null) dispatch(target, "mousemove", x, y, true);
  }

  void applyHoverChange(UINode oldT, UINode newT, float x, float y) {
    ArrayList<UINode> oldChain = chainOf(oldT);
    ArrayList<UINode> newChain = chainOf(newT);

    if (oldT != null) dispatch(oldT, "mouseout", x, y, true);
    if (newT != null) dispatch(newT, "mouseover", x, y, true);

    for (int i = 0; i < oldChain.size(); i++) {
      UINode n = oldChain.get(i);
      n.hovered = false;
      if (!newChain.contains(n)) dispatch(n, "mouseleave", x, y, false);
    }
    for (int i = 0; i < newChain.size(); i++) {
      UINode n = newChain.get(i);
      n.hovered = true;
      if (!oldChain.contains(n)) dispatch(n, "mouseenter", x, y, false);
    }
  }

  void pressed(float x, float y) {
    UINode target = this.root.pick(x, y);
    this.pressedTarget = target;
    if (target != null) {
      target.held = true;
      dispatch(target, "mousedown", x, y, true);
    }
  }

  void released(float x, float y) {
    UINode target = this.root.pick(x, y);
    if (this.pressedTarget != null) this.pressedTarget.held = false;
    if (target != null) {
      dispatch(target, "mouseup", x, y, true);
      if (target == this.pressedTarget) dispatch(target, "click", x, y, true);
    }
    this.pressedTarget = null;
  }

  void dragged(float x, float y) {
    if (this.pressedTarget != null) dispatch(this.pressedTarget, "mousedrag", x, y, true);
    moved(x, y);
  }
}
