Repetier 2 Omron Bridge V0.1 Beta
==============

Repetier serial to Omron FINS ethernet communication

--Dutch--

Studenten aan de Hogeschool Utrecht te Utrecht werken aan de volgende opdracht:

Vorig jaar is er door een H4-projectgroep succesvol een deltarobot gebouwd, opgebouwd uit indu-striële componenten, t.w. een Omron Sysmac controller en 3 ethercat servodrives.
Door de eigenschappen van de toegepaste NJ301-1100 CPU is gebruik tot nu toe beperkt gebleven tot het maken van relatief eenvoudige point-to-point bewegingen, zonder interpolatie.
Rechtlijnige of cirkelvormige bewegingen zijn hierdoor lastig te programmeren.
Om dit te ondervangen is een uitgebreidere CPU besteld waarvan de firmware reeds is voorzien van de benodigde kinematica voor het aansturen van een deltarobot.
Hiermee krijgt de robot daadwer-kelijk de CNC-eigenschappen die bijvoorbeeld nodig zijn voor het realiseren van een 3D-printer.

Opdracht: 
Maak een grondige analyse van de hard- en software die door de projectgroep van vorig jaar is opgeleverd en breng de huidige eigenschappen en beperkingen in kaart.
Bouw de deltarobot om tot een 3D-printer door de noodzakelijke componenten toe te voegen, t.w. genoemde CPU, een extruder voor ABS-kunststofdraad en een verwarmingsplaat.
De 3D-printer moet in staat zijn om (STL-)files uit Solidworks of een ander CAD-pakket te verwerken.


Een onderdeel van dit project is het aansturen van de delta robot met de industriële controller.
Gekozen is voor softwarepakket Repetier om het slicen en denkwerk uit te voeren betreffende het 3D model.
Ook zal Repetier de delta robot moeten aansturen.

Om dit alles te realiseren dient er externe communicatie software gerealiseerd te worden welke de brug legt tussen het seriële protocol van Repetier en het UDP Omron FINS protocol van Omron.
Deze brug zal gelegd worden door open source java pakket Processing.

In deze repository is de Repetier naar FINS software te vinden.
