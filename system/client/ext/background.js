chrome.webRequest.onHeadersReceived.addListener(
    function(details) {
      let headers = details.responseHeaders.filter(header => {
        return !["x-frame-options", "content-security-policy"].includes(header.name.toLowerCase());
      });
      return {responseHeaders: headers};
    },
    {urls: ["<all_urls>"], types: ["sub_frame", "main_frame", "xmlhttprequest"]},
    ["blocking", "responseHeaders"]
  );
  