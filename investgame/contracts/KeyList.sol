// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * contract Example {
 *     // Add the library methods
 *     using KeyList for KeyList.ListItems;
 *
 *     // Declare a set state variable
 *     KeyList.ListItems private myList;
 * }
*/


library KeyList {
   struct SItem {
        uint192 value;
        uint32  left;
        uint32  right;
   }
    
   struct ListItems {
        uint32 first;
        uint32 last;
        uint32 counter;
        mapping(uint32 => SItem) items;
    }
    struct SItemValue
    {
        uint32  key;
        uint192 value;
        //uint32  left;
        //uint32  right;
    }


    function add(
        ListItems storage list,
        uint192 value
    ) internal returns (uint32 key){
        list.counter++;
        key=list.counter;

        list.items[key]=SItem(value,list.last,0);
        if(list.last!=0)
            list.items[list.last].right=key;

        if(list.first==0)
            list.first=key;

        list.last=key;
    }
    

    function remove(
        ListItems storage list,
        uint32 key
    ) internal {
        require(key>0,"KeyList: Zero key");

        SItem memory Item=list.items[key];
        uint32 left=Item.left;
        uint32 right=Item.right;

        if(list.last==key)
            list.last=left;
        if(list.first==key)
            list.first=right;

        if(left!=0)
            list.items[left].right=right;
        if(right!=0)
            list.items[right].left=left;

        delete list.items[key];
    }

   function get(
        ListItems storage list,
        uint32 key
    ) internal view returns  (uint192) {
        require(key>0,"KeyList: Zero key");
        return list.items[key].value;
    }


   function getItems(ListItems storage list, uint32 startKey, uint32 counts)
        internal
        view
        returns (SItemValue[] memory Arr, uint32 retCount)
    {
        if(startKey==0)
            startKey=list.first;
        if(startKey!=0 && counts>0)
        {
            Arr = new SItemValue[](counts);
            retCount=0;
            while(true)
            {
                SItem memory Item=list.items[startKey];
                Arr[retCount]=SItemValue(startKey,Item.value);
                //Arr[retCount]=SItemValue(startKey,Item.value,Item.left,Item.right);

                startKey=Item.right;
                retCount++;
                
                if(startKey==0 || retCount>=counts)
                    break;
            }
        }
    }

}

