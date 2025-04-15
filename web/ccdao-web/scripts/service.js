const axios = require("axios");
const service = axios.create({
  timeout: 30000,
});

service.interceptors.response.use(
  (response) => {
    return response.data;
  },
  (err) => {
    return Promise.reject(err);
  }
);

module.exports = service;
