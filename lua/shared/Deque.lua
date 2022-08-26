
Deque = ClassSimple {
    __init = function(self, tailReserve)
        tailReserve = tailReserve or 0
        self.head = tailReserve
        self.tail = tailReserve + 1
        self.size = 0
        self.capacity = 0
    end;

    Rehead = function(self, tailReserve)
        tailReserve = tailReserve or 0
        local head, tail = self.head, self.tail
        if head > tail then
            local headDelta = head + tailReserve - 1  -- because 1-indexed systems don't add correctly
            if tailReserve < tail then
                -- shift all elements forward
                for i = 1, self.size do
                    self[i + tailReserve] = self[i + headDelta]
                end
            else
                -- shift all elements backward
                for i = self.size, 1, -1 do
                    self[i + tailReserve] = self[i + headDelta]
                end
            end
        else
            -- TODO
        end
    end;

    RawIndex = function(self, index)
        if index > 0 then
            index = index + self.head
        elseif index ~= 0 then
            index = index + self.tail
        else
            return nil
        end
        local cap = self.capacity
        if index > cap then
            index = index - cap
        elseif index < 1 then
            index = index + cap
        end
        return index
    end;

    IsEmpty = function(self)
        return self.size == 0
    end;

    Push = function(self, value)
        local head = self.head + 1
        if head == self.capacity then
            head = 1
        end
        self.head = head
        self[head] = value
    end;
    Peek = function(self)
        return self[self.head]
    end;
    Pop = function(self)
        if self.size == 0 then
            return nil
        end
        local head = self.head
        local value = self[head]
        self[head] = nil
        head = head - 1
        if head == 0 then
            head = self.capacity
        end
        self.head = head
        return value
    end;

    Put = function(self, value)
        local tail = self.tail - 1
        if tail == 0 then
            tail = self.capacity
            if tail == -1 then
                tail = self.head * 2
                self.capacity = tail
            end
        end
        self.tail = tail
        self[tail] = value
    end;
    Preview = function(self)
        return self[self.tail]
    end;
    Poll = function(self)
        if self.size == 0 then
            return nil
        end
        local tail = self.tail
        local value = self[tail]
        self[tail] = nil
        tail = tail + 1
        local cap = self.capacity
        if cap == -1 then
            
        else
            if tail == cap then
                tail = 1
            end
        end
        self.tail = tail
        return value
    end;

    Set = function(self, ind, value)
        ind = self:RawIndex(ind)
        if ind then
            local old = self[ind]
            self[ind] = value
            return old
        end
    end;
    Get = function(self, ind)
        ind = self:RawIndex(ind)
        if ind then
            return self[ind]
        end
    end;
}