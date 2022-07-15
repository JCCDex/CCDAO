const isCCDAO = (token) => token.currency === "CCDAO" && token.issuer === "jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or";

module.exports = {
  isCCDAO,
};
