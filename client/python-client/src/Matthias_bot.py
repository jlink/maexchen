from maexchen_bot import MaexchenBot, Nachrichten


class EinfacherBot(MaexchenBot):
    def reagiere_auf_nachricht(self, nachricht, parameter):

        if (nachricht == Nachrichten.NEUE_RUNDE):
            self.angesagte_wuerfelzahl = [1, 3]  # Niedrigster Würfelwert zu Beginn der Runde
            self.vorherigeSpieler = 0

        if (nachricht == Nachrichten.SPIELER_SAGT_AN):
            self.angesagte_wuerfelzahl = self.zerlege_wuerfel_string(parameter[-1])
            self.zaehleSpieler()

        if (nachricht == Nachrichten.DU_BIST_DRAN):
            token = parameter[-1]
            erwartungswert_wuerfel = [6, 5]
            if self.ist_hoeher(self.angesagte_wuerfelzahl, erwartungswert_wuerfel):
                if (self.vorherigeSpieler >= 5 ):
                    self.schicke_nachricht(Nachrichten.SCHAUEN, [token])
                else:
                    self.schicke_nachricht(Nachrichten.WUERFELN, [token])
            else:
                self.schicke_nachricht(Nachrichten.WUERFELN, [token])

        if (nachricht == Nachrichten.GEWUERFELT):
            gewuerfelte_augen = parameter[0]
            token = parameter[-1]
            gewuerfelte_augen = self.zerlege_wuerfel_string(parameter[0])
            if self.ist_hoeher(gewuerfelte_augen, self.angesagte_wuerfelzahl):
                self.sage_an(gewuerfelte_augen, token)
            else:
                self.luege(token)

    def zaehleSpieler(self):
        self.vorherigeSpieler+=1

    def luege(self, token):
        gelogenen_augen = self.hoeher_als_angesagt()
        self.sage_an(gelogenen_augen, token)

    def sage_an(self, gewuerfelte_augen, token):
        self.schicke_nachricht(Nachrichten.ANSAGEN, [self.fuege_wuerfel_zusammen(gewuerfelte_augen), token])

    def hoeher_als_angesagt(self):
        if self.ist_pasch(self.angesagte_wuerfelzahl):
            if self.angesagte_wuerfelzahl == [6, 6]:
                return [2, 1]
            else:
                return [wuerfel + 1 for wuerfel in self.angesagte_wuerfelzahl]
        else:
            return [1, 1]

if __name__ == "__main__":
    bot = EinfacherBot(server_ip="127.0.0.1", name="matthias_bot")
    bot.starte(automatisch_mitspielen=True)
