local S = {}

S.Points = {
    A2 = {
        Healer = {Position=Vector3.new(-18,0,-12), Label="Solen"},
        River = {Position=Vector3.new(28,0,70), Label="Rives de la Brume"},
        MarauderCamp = {Position=Vector3.new(105,0,45), Label="Camp des Maraudeurs"},
        RuinA = {Position=Vector3.new(-135,0,-65), Label="Première stèle"},
        RuinB = {Position=Vector3.new(-172,0,-105), Label="Deuxième stèle"},
        RuinC = {Position=Vector3.new(-110,0,-145), Label="Troisième stèle"},
        Sanctuary = {Position=Vector3.new(240,0,-155), Label="Sanctuaire d'Astréa"},
        CrystalField = {Position=Vector3.new(10,0,72), Label="Éclats de brume"},
    },
    H2 = {
        Healer = {Position=Vector3.new(-18,0,-12), Label="Tahla"},
        BrokenWagon = {Position=Vector3.new(105,0,45), Label="Chariot brisé"},
        CrystalField = {Position=Vector3.new(10,0,72), Label="Éclats ambrés"},
        CanyonA = {Position=Vector3.new(-125,0,-60), Label="Corniche occidentale"},
        CanyonB = {Position=Vector3.new(-55,0,-125), Label="Fond du canyon"},
        CanyonC = {Position=Vector3.new(105,0,-145), Label="Arche de Khar"},
        SealedGate = {Position=Vector3.new(210,0,-150), Label="Seuil enfoui"},
        TitanPit = {Position=Vector3.new(240,0,-155), Label="Fosse du Titan"},
    },
}

S.Zones = {
    A2 = {
        QuestGiver="Elyra",
        Intro="La vallée était calme. Depuis trois nuits, la brume remonte contre le vent.",
        Quests={
            {
                Id="A2_01", Name="Un camp dans la brume",
                Accept="Avant de partir, retrouve Solen. Il écoute la vallée mieux que quiconque.",
                Complete="Solen l'a senti lui aussi. Quelque chose pousse la faune vers notre camp.",
                Objectives={{Type="Explore", Point="Healer", Amount=1, Text="Retrouver Solen"}},
                Rewards={XP=70, Gold=12},
            },
            {
                Id="A2_02", Name="Sentiers troublés",
                Accept="Les Brumelins ne s'approchaient jamais autant. Dégage le sentier avant l'arrivée du prochain convoi.",
                Complete="Ils fuyaient quelque chose, plus haut dans la vallée.",
                Objectives={{Type="Kill", Target="Brumelin", Amount=4, Text="Vaincre des Brumelins"}},
                Rewards={XP=135, Gold=26},
            },
            {
                Id="A2_03", Name="La rivière silencieuse",
                Accept="L'eau ne chante plus comme avant. Rapporte-moi les éclats bleus qui bordent la source.",
                Complete="Ils vibrent. Pas comme de la magie ordinaire... comme un souvenir qui cherche à parler.",
                Objectives={{Type="Collect", Target="A2Shard", Amount=5, Text="Récolter des éclats de brume", Point="CrystalField"}},
                Rewards={XP=180, Gold=38},
            },
            {
                Id="A2_04", Name="Les fouilleurs du col",
                Accept="Des Maraudeurs retournent les vieilles pierres. Ils savent ce qu'ils cherchent. Découvre quoi.",
                Complete="Ils n'ont pas trouvé un trésor. Ils ont réveillé quelque chose.",
                Objectives={
                    {Type="Kill", Target="MaraudeurA2", Amount=4, Text="Repousser les Maraudeurs"},
                    {Type="Interact", Point="MarauderCamp", Amount=1, Text="Inspecter leur camp"},
                },
                Rewards={XP=245, Gold=52, Tier=2},
            },
            {
                Id="A2_05", Name="Pierres qui se souviennent",
                Accept="Trois stèles entourent le vieux bois. Approche-les. Ne touche à rien si elles commencent à murmurer.",
                Complete="Les trois ont répondu au même instant. L'Écho relie ces ruines entre elles.",
                Objectives={
                    {Type="Explore", Point="RuinA", Amount=1, Text="Atteindre la première stèle"},
                    {Type="Explore", Point="RuinB", Amount=1, Text="Atteindre la deuxième stèle"},
                    {Type="Explore", Point="RuinC", Amount=1, Text="Atteindre la troisième stèle"},
                },
                Rewards={XP=330, Gold=68},
            },
            {
                Id="A2_06", Name="Les gardiens se réveillent",
                Accept="Les Sentinelles se sont relevées. Elles ne nous voient pas comme des intrus : elles obéissent à un ordre ancien.",
                Complete="Alors l'ordre vient du sanctuaire. Nous devons monter.",
                Objectives={{Type="Kill", Target="SentinelleA2", Amount=3, Text="Neutraliser les Sentinelles"}},
                Rewards={XP=430, Gold=92},
            },
            {
                Id="A2_07", Name="L'Écho du sommet",
                Accept="Va jusqu'au sanctuaire. Si la vallée a une voix, c'est là-haut qu'elle parlera.",
                Complete="Une pulsation a traversé toute la vallée. Et quelque chose vient de s'éveiller.",
                Objectives={{Type="Explore", Point="Sanctuary", Amount=1, Text="Atteindre le sanctuaire"}},
                Rewards={XP=500, Gold=110},
            },
            {
                Id="A2_08", Name="Le Colosse d'Astréa",
                Accept="Le Colosse n'est pas notre ennemi. Mais tant que l'Écho le commande, il détruira tout ce qui approche.",
                Complete="Il s'est arrêté... Il gardait la vallée. Quelqu'un a simplement réveillé son dernier ordre.",
                Objectives={{Type="Kill", Target="ColosseA2", Amount=1, Text="Vaincre le Colosse d'Astréa", Point="Sanctuary"}},
                Rewards={XP=780, Gold=185, Tier=3},
            },
        },
    },

    H2 = {
        QuestGiver="Rhaz",
        Intro="Ici, le sable ne pardonne rien. Et depuis peu, même la pierre bouge.",
        Quests={
            {
                Id="H2_01", Name="Aux frontières",
                Accept="Tahla a passé la nuit à soigner des éclaireurs. Va la voir. Ensuite tu sauras pourquoi personne ne dort ici.",
                Complete="Maintenant tu sais. Le désert change sous nos pieds.",
                Objectives={{Type="Explore", Point="Healer", Amount=1, Text="Retrouver Tahla"}},
                Rewards={XP=70, Gold=12},
            },
            {
                Id="H2_02", Name="Sous nos pieds",
                Accept="Les Fouisseurs remontent jusqu'aux palissades. Ils ne chassent pas : ils fuient les profondeurs.",
                Complete="Même les bêtes du désert craignent ce qui s'éveille dessous.",
                Objectives={{Type="Kill", Target="Fouisseur", Amount=4, Text="Vaincre des Fouisseurs"}},
                Rewards={XP=135, Gold=26},
            },
            {
                Id="H2_03", Name="La route rouge",
                Accept="Les Pillards ont frappé un convoi. Repousse-les et trouve ce qu'ils ont laissé derrière eux.",
                Complete="Ils transportaient des fragments de pierre ancienne. Pas de l'or.",
                Objectives={
                    {Type="Kill", Target="PillardH2", Amount=4, Text="Repousser les Pillards"},
                    {Type="Interact", Point="BrokenWagon", Amount=1, Text="Inspecter le chariot brisé"},
                },
                Rewards={XP=250, Gold=54, Tier=2},
            },
            {
                Id="H2_04", Name="Les éclats du canyon",
                Accept="Ces cristaux ambrés vibrent depuis l'attaque. Ramène-m'en assez pour comparer leur signature.",
                Complete="Même résonance que les récits venus d'Astréa. Ce n'est plus un problème local.",
                Objectives={{Type="Collect", Target="H2Shard", Amount=5, Text="Récolter des éclats ambrés", Point="CrystalField"}},
                Rewards={XP=190, Gold=40},
            },
            {
                Id="H2_05", Name="Là où le sol respire",
                Accept="Trois endroits du canyon grondent à intervalles réguliers. Va les écouter toi-même.",
                Complete="Trois battements. Une seule source. Quelque chose est enfoui sous Khar.",
                Objectives={
                    {Type="Explore", Point="CanyonA", Amount=1, Text="Inspecter la corniche"},
                    {Type="Explore", Point="CanyonB", Amount=1, Text="Descendre dans le canyon"},
                    {Type="Explore", Point="CanyonC", Amount=1, Text="Atteindre l'arche"},
                },
                Rewards={XP=340, Gold=70},
            },
            {
                Id="H2_06", Name="Les gardiens de basalte",
                Accept="Les Golems n'ont pas marché depuis des siècles. Aujourd'hui ils bloquent le passage vers l'est.",
                Complete="Des gardiens anciens, réveillés par le même signal.",
                Objectives={{Type="Kill", Target="GolemBasalte", Amount=3, Text="Vaincre les Golems de basalte"}},
                Rewards={XP=440, Gold=94},
            },
            {
                Id="H2_07", Name="Le seuil enfoui",
                Accept="Derrière les plateaux se trouve une porte que personne n'a jamais ouverte. Aujourd'hui, elle résonne.",
                Complete="Le symbole est le même que dans les fragments. Ce seuil appartient au réseau de l'Écho.",
                Objectives={{Type="Explore", Point="SealedGate", Amount=1, Text="Atteindre le seuil enfoui"}},
                Rewards={XP=510, Gold=112},
            },
            {
                Id="H2_08", Name="Le Titan des Marches",
                Accept="Le Titan garde le seuil. Nous ne pouvons pas comprendre ce qui est dessous tant qu'il répond à l'ancien ordre.",
                Complete="Il ne protégeait pas Khar de nous. Il protégeait quelque chose de Khar... et maintenant le chemin est ouvert.",
                Objectives={{Type="Kill", Target="TitanH2", Amount=1, Text="Vaincre le Titan des Marches", Point="TitanPit"}},
                Rewards={XP=800, Gold=190, Tier=3},
            },
        },
    },
}

return S
