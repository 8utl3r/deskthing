// Kindle library export – paste this into the browser Console on:
// https://read.amazon.com/kindle-library
// (DevTools → Console tab, then paste and press Enter)
// Save the downloaded kindle-library.csv to: scripts/servarr/kindle-library.csv

(function () {
  const xhr = new XMLHttpRequest();
  const items = [];
  let csvData = "ASIN,Title,Author,Read%\n";

  function getItemsList(paginationToken = null) {
    const url = "https://read.amazon.com/kindle-library/search?query=&libraryType=BOOKS" +
      (paginationToken ? "&paginationToken=" + paginationToken : "") +
      "&sortType=acquisition_desc&querySize=50";
    xhr.open("GET", url, false);
    xhr.send();
  }

  xhr.onreadystatechange = function () {
    if (xhr.readyState === 4 && xhr.status === 200) {
      const data = JSON.parse(xhr.responseText);
      if (data.itemsList) items.push(...data.itemsList);
      if (data.paginationToken) getItemsList(data.paginationToken);
    }
  };

  getItemsList();
  items.forEach((item) => {
    csvData += '"' + (item.asin || "") + '","' +
      (item.title || "").replace(/"/g, '""') + '","' +
      (item.authors?.[0] || "") + '","' +
      (item.percentageRead || "") + '"\n';
  });

  const a = document.createElement("a");
  a.href = "data:text/csv;charset=utf-8," + encodeURIComponent(csvData);
  a.download = "kindle-library.csv";
  a.click();
  console.log("Exported " + items.length + " books. Save to ~/dotfiles/scripts/servarr/kindle-library.csv");
})();
