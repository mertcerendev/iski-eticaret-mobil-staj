class ApiHatasi extends Error {
  constructor(mesaj, durumKodu) {
    super(mesaj);
    this.durumKodu = durumKodu;
  }
}

module.exports = { ApiHatasi };