CREATE TABLE IF NOT EXISTS `tutorials` (
    id int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    title varchar(255) NOT NULL,
    description varchar(255),
    published BOOLEAN DEFAULT false
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `tutorials` (id, title, description, published) VALUES
    (1, "Node.js Basics",            'Tut#1 Description', false),
    (2, "Rest APIs",                 'Tut#2 Description', false),
    (3, "Node Rest APIs",            'Tut#3 Description', false),
    (4, "MySQL database",            'Tut#4 Description', false),
    (5, "Node Rest Apis with MySQL", 'Tut#5 Description', false);
