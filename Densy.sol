contract Densy {
    address private owner;
    address private notary;

    constructor() public {
        owner = msg.sender; // Чеканщик - распределение токенов
        notary = msg.sender; // Нотариус - распределение активов
    }

    struct Offer {
        bool way;
        address owner;
        uint essence;
        uint count;
        uint price;
    }
    
    uint private countCoin = 0;
    mapping (uint => Offer) private offers; // Стакан
    mapping (address => uint) private balances; // Баланс токенов
    mapping (address => mapping (uint => uint)) private holdings; // Все активы
    
    // Добавление монет
    
    function mintToken(address user, uint count) public {
        if (msg.sender == owner) {
            balances[user] += count;
            countCoin += count;
        }
    }
    
    // Изменение активов
    
    function mintAssetInc(address user, uint essence, uint count) public {
        if (msg.sender == notary) {
            holdings[user][essence] += count;
        }
    }
    
    function mintAssetDec(address user, uint essence, uint count) public {
        if (msg.sender == notary) {
            if (holdings[user][essence] >= count) {
                holdings[user][essence] -= count;
            }
        }
    }
    
    // Добавить предложение
    // way: true - продажа, false - покупка
    
    function addOffer(bool way, uint id, uint essence, uint count, uint price) public {
        if (holdings[msg.sender][essence] >= count && price > 0) {
            offers[id] = Offer({
                way: way,
                owner: msg.sender,
                essence: essence,
                count: count,
                price: price
            });

            // Замораживание активов, если на продажу
            if (way) {
                holdings[msg.sender][essence] -= count;
            }
        }
    }

    // Схлопывание сделки
    // idIn - продажа, idOut - покупка

    function swapOffer(uint idIn, uint idOut) public {
        address ownerIn = offers[idIn].owner;
        address ownerOut = offers[idOut].owner;

        address access;
        if (idIn > idOut) {
            access = ownerIn;
        } else {
            access = ownerOut;
        }

        // Первый продавец?
        bool cond_in = offers[idIn].way;
        // Второй покупатель?
        bool cond_out = !offers[idOut].way;
        // Вызывает инициатор?
        bool cond_access = access == msg.sender;
        // Цена предложения меньше цены покупки?
        bool cond_price = offers[idIn].price < offers[idOut].price;

        if (cond_in && cond_out && cond_access && cond_price) {
            uint price;
            uint count;

            // Определение выгодного для тейкера курса

            if (idIn > idOut) {
                price = offers[idOut].price;
            } else {
                price = offers[idIn].price;
            }
            
            // Случай частичной сделки
            
            if (offers[idIn].count < offers[idOut].count) {
                count = offers[idIn].count;
            } else {
                count = offers[idOut].count;
            }
            
            // Итоговая сумма сделки
            // Объёмы скрыты
            
            uint sum = price * count;
            
            if (balances[ownerOut] >= sum) {
                // Изменение балансов
                balances[ownerIn] += sum;
                balances[ownerOut] -= sum;
                
                // Перечисление активов
                holdings[ownerOut][offers[idOut].essence] += count;

                // Изменение выполненного количества активов в заявке
                offers[idIn].count -= count;
                offers[idOut].count -= count;
                
                // Закрытие выполненных заявок
                if (offers[idIn].count == 0) {
                    delete offers[idIn];
                }
                if (offers[idOut].count == 0) {
                    delete offers[idOut];
                }
            }
        }
    }

    // Проверка состояний

    function getTokens(address user) public view returns (uint) {
        if (msg.sender == owner) {
            return balances[user];
        }
    }

    function getAssets(address user, uint essence) public view returns (uint) {
        if (msg.sender == owner) {
            return holdings[user][essence];
        }
    }

    function getOffer(uint id) public view returns (uint) {
        if (msg.sender == owner) {
            return offers[id].price;
        }
    }
}