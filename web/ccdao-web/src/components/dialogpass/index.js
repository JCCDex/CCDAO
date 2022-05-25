import Dialogpass from "./dialogpass";

import render from "../../render";

const ImportDialogPass = (() => {
  let append = false;
  const v = render({ component: Dialogpass });
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

export default ImportDialogPass;
