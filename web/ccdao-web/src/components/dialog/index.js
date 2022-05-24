import Dialog from "./dialog";

import render from "../../render";

const ImportDialog = (() => {
  let append = false;
  const v = render({ component: Dialog });
  v.$mount();
  const child = v.$children[0];

  return () => {
    if (!append) {
      document.body.appendChild(v.$el);
      append = true;
    }

    return child;
  };
})();

export default ImportDialog;
